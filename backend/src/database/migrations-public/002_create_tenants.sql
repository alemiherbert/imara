-- TENANT REGISTRY (Public Schema)
-- Global catalog of all tenants (SACCOs) in the system

CREATE TABLE public.tenants(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identification
    code varchar(50) NOT NULL UNIQUE,
    sacco_name varchar(255) NOT NULL,
    short_name varchar(100),
    subdomain varchar(63) NOT NULL UNIQUE,
    
    -- Schema Information
    schema_name varchar(63) NOT NULL UNIQUE,
    
    -- Contact Information
    contact_email varchar(255) NOT NULL,
    contact_phone varchar(50) NOT NULL,
    address jsonb, -- { "street": "", "city": "", "country": "" }

    -- Branding (Consolidated into JSONB)
    branding jsonb DEFAULT '{"logo_url": null, "primary_color": "#1e40af", "secondary_color": "#3b82f6"}'::jsonb,

    -- Subscription & Limits
    subscription_tier varchar(20) DEFAULT 'trial',
    subscription_expires_at timestamptz,
    max_users integer DEFAULT 10 CHECK (max_users > 0),
    max_members integer DEFAULT 100 CHECK (max_members > 0),
    
    -- Status
    status varchar(20) DEFAULT 'active' NOT NULL CHECK (status in ('active', 'suspended', 'inactive')),
    
    -- Application Settings
    settings jsonb DEFAULT '{}'::jsonb,
    
    -- Audit
    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);

-- INDEXES
CREATE INDEX tenants_status_idx ON public.tenants(status);
CREATE INDEX tenants_schema_name_idx ON public.tenants(schema_name);
CREATE INDEX tenants_subdomain_idx ON public.tenants(subdomain);

-- TRIGGER: Auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
    RETURNS TRIGGER
    AS $$ BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
 $$ LANGUAGE plpgsql;

CREATE TRIGGER tenants_set_updated_at
    BEFORE UPDATE ON public.tenants
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();
