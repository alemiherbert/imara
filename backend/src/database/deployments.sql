-- DEPLOYMENT SCRIPT
-- This file handles the core infrastructure for multi-tenancy.
-- 1. Locks down the public schema.
-- 2. Creates the 'template' schema (the blueprint for new tenants).
-- 3. Defines SQL Functions to provision new tenants dynamically.

-- Fix: schema does not exist error
CREATE SCHEMA IF NOT EXISTS template;

-- SYSTEM SETUP: Lock down default schemas
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO PUBLIC;
REVOKE ALL ON SCHEMA template FROM PUBLIC;

-- AUDIT TABLE
-- Logs the creation and deletion of tenant schemas for security auditing
CREATE TABLE IF NOT EXISTS public.tenant_audit_log (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    schema_name varchar(63) NOT NULL,
    tenant_code varchar(50),
    operation varchar(20) NOT NULL, -- 'CREATE', 'DROP'
    performed_by varchar(100) DEFAULT current_user,
    performed_at timestamptz DEFAULT now(),
    details jsonb,
    error_message text
);

-- Create the Template Schema container if it doesn't exist
CREATE SCHEMA IF NOT EXISTS template;

-- =================================================================
-- FUNCTION: create_tenant_schema
-- Creates the schema, role, and clones tables from 'template'
-- =================================================================
DROP FUNCTION IF EXISTS create_tenant_schema(varchar);

CREATE OR REPLACE FUNCTION create_tenant_schema(p_schema_name varchar)
    RETURNS void
    AS $$ DECLARE
    v_table_name text;
    v_constraint_def text;
    v_fk record;
    v_role_name text := p_schema_name || '_role';
BEGIN
    -- 1. INPUT VALIDATION (Critical Security)
    -- Prevent overwriting system schemas
    IF p_schema_name IN ('template', 'public', 'pg_catalog', 'information_schema', 'pg_toast', 'pg_temp') THEN
        RAISE EXCEPTION 'Illegal schema name: Cannot create schema named "%"', p_schema_name;
    END IF;

    -- Validate schema name format (lowercase letters, numbers, underscores only)
    IF p_schema_name !~ '^[a-z_][a-z0-9_]*$' THEN
        RAISE EXCEPTION 'Invalid schema name format. Use lowercase letters, numbers, and underscores only.';
    END IF;

    -- 2. CREATE ROLE
    BEGIN
        EXECUTE format('CREATE ROLE %I', v_role_name);
    EXCEPTION
        WHEN duplicate_object THEN
            RAISE NOTICE 'Role % already exists, skipping creation.', v_role_name;
    END;

    -- 3. CREATE SCHEMA
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', p_schema_name);

    -- 4. CLONE TABLES FROM TEMPLATE
    -- 'LIKE ... INCLUDING ALL' copies structure, defaults, constraints (except FKs), and indexes
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'template'
          AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('CREATE TABLE %I.%I (LIKE template.%I INCLUDING ALL)', p_schema_name, v_table_name, v_table_name);
    END LOOP;

    -- 5. RECREATE FOREIGN KEYS
    -- LIKE does not copy FKs. We must recreate them manually.
    -- Safe because p_schema_name is validated via Regex above.
    FOR v_fk IN
        SELECT
            tc.table_name,
            tc.constraint_name,
            pg_get_constraintdef(c.oid) AS constraint_def
        FROM information_schema.table_constraints tc
        JOIN pg_constraint c ON c.conname = tc.constraint_name
        WHERE tc.table_schema = 'template'
          AND tc.constraint_type = 'FOREIGN KEY'
    LOOP
        -- Replace 'template.' prefix with new schema prefix
        v_constraint_def := replace(v_fk.constraint_def, 'template.', p_schema_name || '.');
        
        EXECUTE format('ALTER TABLE %I.%I ADD CONSTRAINT %I %s', 
                       p_schema_name, v_fk.table_name, v_fk.constraint_name, v_constraint_def);
    END LOOP;

    -- 6. DEFAULT PRIVILEGES
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', p_schema_name, v_role_name);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT USAGE, SELECT ON SEQUENCES TO %I', p_schema_name, v_role_name);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT EXECUTE ON FUNCTIONS TO %I', p_schema_name, v_role_name);

    RAISE NOTICE 'Schema % structure created successfully', p_schema_name;
END;
 $$ LANGUAGE plpgsql;

-- =================================================================
-- FUNCTION: drop_tenant_schema
-- Drops a schema and its associated role
-- =================================================================
DROP FUNCTION IF EXISTS drop_tenant_schema(varchar);

CREATE OR REPLACE FUNCTION drop_tenant_schema(p_schema_name varchar)
    RETURNS void
    AS $$ BEGIN
    -- Input Validation
    IF p_schema_name IN ('template', 'public', 'pg_catalog', 'information_schema', 'pg_toast', 'pg_temp') THEN
        RAISE EXCEPTION 'Forbidden: Cannot drop system schema "%"', p_schema_name;
    END IF;

    -- Log the drop action
    INSERT INTO public.tenant_audit_log (schema_name, operation, details)
    VALUES (p_schema_name, 'DROP', jsonb_build_object('triggered_by', current_user));

    EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', p_schema_name);

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_schema_name || '_role') THEN
        EXECUTE format('DROP ROLE IF EXISTS %I', p_schema_name || '_role');
    END IF;

    RAISE NOTICE 'Schema % and role dropped successfully', p_schema_name;
END;
$$ LANGUAGE plpgsql;

-- =================================================================
-- FUNCTION: create_tenant_with_security
-- Main entry point to create a fully configured tenant
-- =================================================================
DROP FUNCTION IF EXISTS create_tenant_with_security(varchar, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION create_tenant_with_security(p_schema_name varchar, p_tenant_code varchar, p_password varchar, p_contact_email varchar, p_contact_phone varchar)
    RETURNS uuid
    AS $$ DECLARE
    v_tenant_id uuid;
    v_role_name text := p_schema_name || '_role';
BEGIN
    -- 1. CREATE STRUCTURE
    PERFORM create_tenant_schema(p_schema_name);

    -- 2. CONFIGURE ROLE
    EXECUTE format('ALTER ROLE %I NOINHERIT LOGIN', v_role_name);

    IF p_password IS NOT NULL THEN
        IF length(p_password) < 12 THEN
            RAISE EXCEPTION 'Password must be at least 12 characters';
        END IF;
        EXECUTE format('ALTER ROLE %I PASSWORD %L', v_role_name, p_password);
        EXECUTE format('ALTER ROLE %I VALID UNTIL %L', v_role_name, (now() + interval '1 day')::text);
    END IF;

    -- 3. GRANT PERMISSIONS
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', p_schema_name, v_role_name);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO %I', p_schema_name, v_role_name);
    EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I', p_schema_name, v_role_name);
    EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I', p_schema_name, v_role_name);

    -- 4. INSERT TENANT RECORD
    INSERT INTO public.tenants (
        code, 
        sacco_name,
        schema_name, 
        subdomain,
        contact_email,
        contact_phone
    ) VALUES (
        p_tenant_code,
        p_tenant_code,
        p_schema_name,
        p_tenant_code,
        p_contact_email,
        p_contact_phone
    )
    RETURNING id INTO v_tenant_id;

    -- 5. AUDIT LOG
    INSERT INTO public.tenant_audit_log (schema_name, tenant_code, operation, details)
    VALUES (p_schema_name, p_tenant_code, 'CREATE', jsonb_build_object('role_name', v_role_name));

    RETURN v_tenant_id;
END;
$$ LANGUAGE plpgsql;
