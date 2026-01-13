-- ROLES
-- Defines system roles (e.g., 'Member', 'Accountant', 'Auditor', 'Admin')
CREATE TABLE template.roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    
    name varchar(100) NOT NULL UNIQUE,
    display_name varchar(100),
    description text,
    
    is_system_role boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    hierarchy_level integer check(hierarchy_level > 0) DEFAULT 1,
    
    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);

-- PERMISSIONS
-- Defines granular actions (e.g., 'loan_approve', 'report_view')
CREATE TABLE template.permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    
    resource varchar(100) NOT NULL,
    action varchar(50) NOT NULL,
    scope varchar(50) DEFAULT 'sacco',
    
    name varchar(100) NOT NULL,
    description text,
    
    is_system_permission boolean DEFAULT false NOT NULL,
    requires_approval boolean DEFAULT false NOT NULL,
    approval_threshold integer CHECK (approval_threshold IS NULL OR approval_threshold >= 0),
    
    created_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);

-- ROLE PERMISSIONS
-- Maps Permissions to Roles
CREATE TABLE template.role_permissions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id uuid NOT NULL REFERENCES template.roles(id) ON DELETE CASCADE,
    permission_id uuid NOT NULL REFERENCES template.permissions(id) ON DELETE CASCADE,
    
    is_granted boolean DEFAULT true NOT NULL,
    conditions jsonb,
    restrictions jsonb,
    
    granted_by uuid,
    granted_at timestamptz DEFAULT now(),
    
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);