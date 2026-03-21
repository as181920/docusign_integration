# Ensure baseline records required by the host app and engines.

organization_name = ENV.fetch("app_default_organization_name", "DocuSignIntegration").to_s.strip
organization_name = "DocuSignIntegration" if organization_name.blank?

organization = OrganizationAuth::Organization.find_by(name: organization_name)

if organization.blank?
  uid_base = organization_name.parameterize(separator: "_").presence || "docusign_integration"
  candidate_uid = uid_base
  suffix = 1

  while OrganizationAuth::Organization.exists?(uid: candidate_uid)
    suffix += 1
    candidate_uid = "#{uid_base}_#{suffix}"
  end

  organization = OrganizationAuth::Organization.create!(
    name: organization_name,
    uid: candidate_uid
  )
end

puts "[seeds] default organization: name=#{organization.name} uid=#{organization.uid}"

demo_tenant_uid = ENV.fetch("app_demo_tenant_uid", "demo").to_s.strip
demo_tenant_uid = "demo" if demo_tenant_uid.blank?
demo_tenant_name = ENV.fetch("app_demo_tenant_name", "Demo Merchant").to_s.strip
demo_tenant_name = "Demo Merchant" if demo_tenant_name.blank?

demo_username = ENV.fetch("app_demo_username", "demo").to_s.strip
demo_username = "demo" if demo_username.blank?
demo_password = ENV.fetch("app_demo_password", "password").to_s
demo_password = "password" if demo_password.blank?

demo_tenant = TenantAuth::Tenant.find_or_initialize_by(uid: demo_tenant_uid)
if demo_tenant.new_record?
  candidate_name = demo_tenant_name
  suffix = 1

  while TenantAuth::Tenant.exists?(name: candidate_name)
    suffix += 1
    candidate_name = "#{demo_tenant_name}_#{suffix}"
  end

  demo_tenant.name = candidate_name
end

demo_tenant.organization = organization
demo_tenant.state ||= 0 if demo_tenant.respond_to?(:state)
demo_tenant.save!

demo_user = TenantAuth::User.find_or_initialize_by(name: demo_username)
demo_user.tenant = demo_tenant
demo_user.password = demo_password
demo_user.password_confirmation = demo_password if demo_user.respond_to?(:password_confirmation=)
demo_user.root = false if demo_user.respond_to?(:root=)
demo_user.save!

puts "[seeds] demo tenant: uid=#{demo_tenant.uid} name=#{demo_tenant.name} id=#{demo_tenant.id}"
puts "[seeds] demo user: name=#{demo_user.name} tenant_id=#{demo_user.tenant_id} password=#{demo_password}"
