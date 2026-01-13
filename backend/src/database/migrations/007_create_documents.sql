-- IDENTITY DOCUMENTS
CREATE TABLE template.identity_documents(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id uuid NOT NULL REFERENCES template.persons(id) ON DELETE CASCADE,

    document_type varchar(50) NOT NULL,
    document_number varchar(100) NOT NULL,
    issue_date date,
    expiry_date date,
    issuing_authority varchar(255),
    issuing_country varchar(100),

    front_image_url varchar(500),
    back_image_url varchar(500),
    selfie_image_url varchar(500),

    verification_status varchar(20) check(verification_status in ('pending', 'approved', 'rejected')) DEFAULT 'pending' NOT NULL,
    verified_by uuid,
    verified_at timestamptz,
    verification_notes text,
    rejection_reason text,

    metadata jsonb,

    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);
