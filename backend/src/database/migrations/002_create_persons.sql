-- PERSONS
CREATE TABLE template.persons(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    first_name varchar(100) NOT NULL,
    middle_name varchar(100),
    last_name varchar(100) NOT NULL,
    date_of_birth date,
    gender varchar(20) check(gender in ('male', 'female', 'other', 'unknown')) DEFAULT 'unknown' NOT NULL,
    marital_status varchar(20) check(gender in ('single', 'married', 'divorced', 'widowed')) DEFAULT 'single' NOT NULL,
    life_status varchar(20) check(gender in ('alive', 'deceased')) DEFAULT 'alive' NOT NULL,
    nationality varchar(100) DEFAULT 'Ugandan',

    primary_phone varchar(50) NOT NULL,
    secondary_phone varchar(50),
    personal_email varchar(255),

    photo_url varchar(500),
    signature_url varchar(500),

    physical_address jsonb,
    employment_details jsonb,
    next_of_kin jsonb,

    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);