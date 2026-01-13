-- Schema migration tracking (per tenant)
CREATE TABLE public.tenant_migrations(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid REFERENCES public.tenants(id) ON DELETE CASCADE,
    migration_name varchar(255) NOT NULL,
    migration_version integer NOT NULL,
    applied_at timestamptz DEFAULT now() NOT NULL,
    executed_by uuid,
    UNIQUE (tenant_id, migration_name)
);