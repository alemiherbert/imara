-- MEMBERSHIPS (Template Schema)
-- Tracks subscription products that members pay for.
-- A member can have multiple memberships over time (history).
-- Memberships determine the active state of a member based on payment status.

CREATE TABLE template.memberships (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id uuid NOT NULL REFERENCES template.members(id) ON DELETE CASCADE,
    
    -- Duration
    start_date date NOT NULL,
    end_date date,
    
    -- Status
    status varchar(20) check(status in ('active', 'pending', 'expired', 'cancelled')) DEFAULT 'active' NOT NULL,
    
    -- Financials (Captured at subscription time)
    registration_fee_paid numeric(20, 4) DEFAULT 0,
    membership_fee numeric(20, 4) DEFAULT 0,
    billing_cycle varchar(20), -- e.g. 'monthly', 'quarterly', 'annual'
    next_billing_date date,
    last_billing_date date,
    
    -- Payment Tracking
    is_paid boolean DEFAULT false,
    payment_status varchar(20) check(payment_status in ('pending', 'paid', 'failed')) DEFAULT 'pending',
    
    -- Settings
    auto_renew boolean DEFAULT true,
    
    -- Cancellation Details
    cancelled_date date,
    cancelled_by uuid,
    cancellation_reason text,
    
    -- Metadata
    assigned_by uuid,
    notes text,
    
    -- Audit
    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);
