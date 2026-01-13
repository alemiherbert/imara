-- STAFF
-- `staff` and `persons` have a one-to-one relationship
CREATE TABLE template.staff(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid NOT NULL REFERENCES template.persons(id) ON DELETE CASCADE,
    role_id uuid REFERENCES template.roles(id),
    staff_number varchar(50) NOT NULL,

    work_email varchar(255) NOT NULL,
    work_phone varchar(50),

    department varchar(100),
    job_title varchar(100),

    employment_status varchar(20) check(employment_status in ('active', 'inactive', 'terminated')) DEFAULT 'active' NOT NULL,
    employment_type varchar(20) check(employment_type in ('permanent', 'contract', 'temporary')) DEFAULT 'permanent',

    hire_date date NOT NULL,
    confirmation_date date,
    termination_date date,
    termination_reason text,

    reports_to uuid REFERENCES template.staff(id) ON DELETE SET NULL,

    preferences jsonb DEFAULT '{}'::jsonb,

    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);
