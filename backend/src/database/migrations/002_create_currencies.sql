-- REFERENCE DATA: Currencies
CREATE TABLE template.currencies(
    code varchar(3) PRIMARY KEY,
    name varchar(100) NOT NULL,
    symbol varchar(10),
    decimal_places smallint DEFAULT 2,
    is_active boolean DEFAULT TRUE NOT NULL,
    
    created_by uuid,
    updated_by uuid,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    deleted_at timestamptz
);

-- Seed Data
INSERT INTO template.currencies(code, name, symbol, decimal_places)
VALUES
    ('UGX', 'Uganda Shilling', 'USh', 0),
    ('KES', 'Kenya Shilling', 'KSh', 2),
    ('USD', 'US Dollar', '$', 2),
    ('EUR', 'Euro', '€', 2);