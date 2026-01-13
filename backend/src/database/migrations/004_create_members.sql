-- MEMBERS
-- `members` and `persons` have a one-to-one relationship
CREATE TABLE template.members(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid NOT NULL REFERENCES template.persons(id) ON DELETE CASCADE,
    member_number varchar(50) NOT NULL,

    status varchar(20) check(status in ('active', 'inactive', 'suspended', 'closed')) DEFAULT 'active' NOT NULL,
    joined_date date NOT NULL,
    approved_date date,
    approved_by uuid,
    exit_date date,
    exit_reason text,

    referred_by uuid REFERENCES template.members(id) ON DELETE SET NULL,

    kyc_status varchar(20) check(kyc_status in ('not_started', 'in_progress', 'completed', 'approved', 'rejected')) DEFAULT 'not_started',
    kyc_completed_at timestamptz,
    kyc_approved_by uuid,
    risk_rating varchar(20) check(risk_rating in ('low', 'medium', 'high')) DEFAULT 'low',

    preferences jsonb DEFAULT '{}'::jsonb,

    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);