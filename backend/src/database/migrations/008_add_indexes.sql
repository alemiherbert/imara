-- INDEXES (Template)

-- Access Control
CREATE UNIQUE INDEX permissions_unique ON template.permissions(resource, action, scope) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX role_permissions_unique ON template.role_permissions(role_id, permission_id) WHERE deleted_at IS NULL;

-- Role Permissions lookup indexes
CREATE INDEX role_permissions_role_idx ON template.role_permissions(role_id) WHERE deleted_at IS NULL;
CREATE INDEX role_permissions_permission_idx ON template.role_permissions(permission_id) WHERE deleted_at IS NULL;

-- Permissions resource lookup
CREATE INDEX permissions_resource_idx ON template.permissions(resource) WHERE deleted_at IS NULL;

-- Roles active lookup
CREATE INDEX roles_active_idx ON template.roles(is_active) WHERE deleted_at IS NULL;

-- Persons
CREATE UNIQUE INDEX persons_phone_unique ON template.persons(primary_phone) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX persons_email_unique ON template.persons(personal_email) WHERE personal_email IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX persons_name_idx ON template.persons(last_name, first_name);

-- Members
CREATE UNIQUE INDEX members_number_unique ON template.members(member_number) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX members_person_unique ON template.members(person_id) WHERE deleted_at IS NULL;
CREATE INDEX members_status_idx ON template.members(status);

-- Staff
CREATE UNIQUE INDEX staff_number_unique ON template.staff(staff_number) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX staff_person_unique ON template.staff(person_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX staff_email_unique ON template.staff(work_email) WHERE deleted_at IS NULL;


-- Memberships
CREATE INDEX memberships_member_id_idx ON template.memberships(member_id) WHERE deleted_at IS NULL;
CREATE INDEX memberships_status_idx ON template.memberships(status) WHERE deleted_at IS NULL;
CREATE INDEX memberships_next_billing_idx ON template.memberships(next_billing_date) WHERE next_billing_date IS NOT NULL AND deleted_at IS NULL;

-- Only one active membership per member
CREATE UNIQUE INDEX memberships_one_active ON template.memberships(member_id) WHERE status = 'active' AND deleted_at IS NULL;
