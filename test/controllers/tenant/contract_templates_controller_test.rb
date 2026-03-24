require "test_helper"

class TenantContractTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    @template_v1 = create(:contract_template, :acme_v1, tenant: @tenant)
    @template_v2 = create(:contract_template, :acme_v2, tenant: @tenant)

    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @tenant_user.name)
  end

  test "index returns current tenant templates" do
    get "/t/acme/contract_templates", as: :json

    assert_response :success
    names = json_body.map { |row| row["name"] }

    assert names.all? { |name| name == "Master Service Agreement" }
  end

  test "index defaults to newest first" do
    get "/t/acme/contract_templates", as: :json

    assert_response :success
    ids = json_body.map { |row| row["id"] }

    assert_equal ids.sort.reverse, ids
  end

  test "index supports pagination" do
    create_list(:contract_template, 12, tenant: @tenant, name: "Paged Template")

    get "/t/acme/contract_templates", params: { per: 5 }, as: :json

    assert_response :success
    assert_equal 5, json_body.size
  end

  test "index supports ransack filtering" do
    create(:contract_template, tenant: @tenant, name: "Alpha Template", docusign_template_id: "tpl_alpha")
    create(:contract_template, tenant: @tenant, name: "Beta Template", docusign_template_id: "tpl_beta")

    get "/t/acme/contract_templates", params: { q: { name_or_docusign_template_id_cont: "alpha" } }, as: :json

    assert_response :success
    assert_operator json_body.size, :>=, 1
    assert json_body.all? { |row| "#{row["name"]} #{row["docusign_template_id"]}".downcase.include?("alpha") }
  end

  test "index html only renders table and no inline create form" do
    get "/t/acme/contract_templates"

    assert_response :success
    assert_select "h1", text: "模板列表"
    assert_select "table", 1
    assert_select "form", 2
    assert_select "form input[name='contract_template[name]']", 0
  end

  test "index html renders english when locale is en" do
    get "/t/acme/contract_templates", params: { locale: "en" }

    assert_response :success
    assert_select "h1", text: "Template List"
    assert_select "a", text: "New Template"
    assert_match("locale=en", response.body)
  end

  test "new renders standalone create form" do
    get "/t/acme/contract_templates/new"

    assert_response :success
    assert_select "h1", text: "新建合同模板"
    assert_select "form", 1
  end

  test "show returns template" do
    get "/t/acme/contract_templates/#{@template_v1.id}", as: :json

    assert_response :success
    assert_equal @template_v1.id, json_body["id"]
  end

  test "edit renders standalone update form" do
    get "/t/acme/contract_templates/#{@template_v1.id}/edit"

    assert_response :success
    assert_select "h1", text: /编辑模板/
    assert_select "form", 1
  end

  test "create auto increments version when missing" do
    assert_difference ["ContractTemplate.count", "AuditLog.count"], +1 do
      post "/t/acme/contract_templates", params: {
        contract_template: {
          name: "Master Service Agreement",
          docusign_template_id: "tpl_new"
        }
      }, as: :json
    end

    assert_response :created
    assert_equal 3, json_body["version"]
  end

  test "update returns updated template" do
    patch "/t/acme/contract_templates/#{@template_v1.id}", params: {
      contract_template: {
        description: "Updated description"
      }
    }, as: :json

    assert_response :success
    assert_equal "Updated description", json_body["description"]
    assert_equal "Updated description", @template_v1.reload.description
  end
end
