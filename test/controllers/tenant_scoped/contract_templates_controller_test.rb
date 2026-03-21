require "test_helper"

class TenantScopedContractTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    @template_v1 = create(:contract_template, :acme_v1, tenant: @tenant)
    @template_v2 = create(:contract_template, :acme_v2, tenant: @tenant)
  end

  test "index returns current tenant templates" do
    get "/t/acme/contract_templates"

    assert_response :success
    names = json_body.map { |row| row["name"] }

    assert names.all? { |name| name == "Master Service Agreement" }
  end

  test "show returns template" do
    get "/t/acme/contract_templates/#{@template_v1.id}"

    assert_response :success
    assert_equal @template_v1.id, json_body["id"]
  end

  test "create auto increments version when missing" do
    assert_difference ["ContractTemplate.count", "AuditLog.count"], +1 do
      post "/t/acme/contract_templates", params: {
        contract_template: {
          name: "Master Service Agreement",
          docusign_template_id: "tpl_new"
        }
      }
    end

    assert_response :created
    assert_equal 3, json_body["version"]
  end

  test "update returns updated template" do
    patch "/t/acme/contract_templates/#{@template_v1.id}", params: {
      contract_template: {
        description: "Updated description"
      }
    }

    assert_response :success
    assert_equal "Updated description", json_body["description"]
    assert_equal "Updated description", @template_v1.reload.description
  end
end
