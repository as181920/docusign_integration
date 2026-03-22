require "test_helper"

class TenantContractsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @acme_tenant = create(:tenant, :acme)
    @acme_user = create(:tenant_user, :alice, tenant: @acme_tenant)
    @acme_connection = create(:tenant_docusign_connection, :acme_connection, tenant: @acme_tenant, connected_by_tenant_user: @acme_user)

    @acme_contract = create(:contract, :acme_contract, tenant: @acme_tenant, creator_tenant_user: @acme_user)
    @acme_primary_signer = create(:contract_signer, contract: @acme_contract, name: "Alice Signer", email: "alice.signer@example.com", role_name: "signer", routing_order: 1)
    create(:contract_signer, :carbon_copy, contract: @acme_contract, name: "Legal CC", email: "legal.cc@example.com", role_name: "cc", routing_order: 2)
    @acme_envelope = create(:contract_envelope, :acme_envelope, contract: @acme_contract, tenant_docusign_connection: @acme_connection)

    @beta_tenant = create(:tenant, :beta)
    @beta_user = create(:tenant_user, :bob, tenant: @beta_tenant)
    create(:contract, :beta_contract, tenant: @beta_tenant, creator_tenant_user: @beta_user)

    @template_v2 = create(:contract_template, :acme_v2, tenant: @acme_tenant)

    sign_in_tenant_user(tenant_uid: @acme_tenant.uid, name: @acme_user.name)
  end

  test "index returns current tenant contracts" do
    get "/t/acme/contracts", as: :json

    assert_response :success
    ids = json_body.map { |row| row["id"] }

    assert_includes ids, @acme_contract.id
    assert_not_includes ids, Contract.find_by!(tenant: @beta_tenant).id
  end

  test "index supports pagination" do
    create_list(:contract, 12, tenant: @acme_tenant, creator_tenant_user: @acme_user)

    get "/t/acme/contracts", params: { per: 5 }, as: :json

    assert_response :success
    assert_equal 5, json_body.size
  end

  test "index supports ransack filtering" do
    create(:contract, tenant: @acme_tenant, creator_tenant_user: @acme_user, title: "Alpha Search Contract", contract_no: "ALPHA-999")
    create(:contract, tenant: @acme_tenant, creator_tenant_user: @acme_user, title: "Beta Search Contract", contract_no: "BETA-999")

    get "/t/acme/contracts", params: { q: { title_or_contract_no_cont: "ALPHA-999" } }, as: :json

    assert_response :success
    assert_operator json_body.size, :>=, 1
    assert json_body.all? { |row| "#{row["title"]} #{row["contract_no"]}".include?("ALPHA-999") }
  end

  test "index html only renders table and no inline create form" do
    get "/t/acme/contracts"

    assert_response :success
    assert_select "h1", text: "合同列表"
    assert_select "a", text: "新建合同"
    assert_select "table", 1
    assert_select "form", 1
  end

  test "index html renders english when locale is en" do
    get "/t/acme/contracts", params: { locale: "en" }

    assert_response :success
    assert_select "h1", text: "Contract List"
    assert_select "a", text: "New Contract"
    assert_match("locale=en", response.body)
  end

  test "new renders standalone contract form" do
    get "/t/acme/contracts/new"

    assert_response :success
    assert_select "h1", text: "新建合同"
    assert_select "form", 1
  end

  test "show returns contract with signers and envelope" do
    get "/t/acme/contracts/#{@acme_contract.id}", as: :json

    assert_response :success
    assert_equal @acme_contract.id, json_body["id"]
    emails = json_body["contract_signers"].map { |row| row["email"] }

    assert_includes emails, "alice.signer@example.com"
    assert_includes emails, "legal.cc@example.com"
    assert_equal @acme_envelope.id, json_body["contract_envelope"]["id"]
  end

  test "create applies contract template metadata" do
    assert_difference ["Contract.count", "AuditLog.count"], +1 do
      post "/t/acme/contracts", params: {
        contract: {
          title: "New Contract",
          contract_no: "C-ACME-NEW-001",
          contract_template_id: @template_v2.id
        }
      }, as: :json
    end

    assert_response :created
    assert_equal @template_v2.docusign_template_id, json_body["docusign_template_id"]
    assert_equal @template_v2.id, json_body["metadata"]["contract_template_id"]
  end

  test "docusign_envelope_submission returns envelope payload" do
    stubbed_envelope = ContractEnvelope.new(
      contract: @acme_contract,
      tenant_docusign_connection: @acme_connection,
      envelope_id: "env-stub-001",
      status: "sent"
    )

    Docusign::EnvelopeSender.stubs(:call).returns(stubbed_envelope)
    post "/t/acme/contracts/#{@acme_contract.id}/docusign_envelope_submission", as: :json

    assert_response :success
    assert_equal "env-stub-001", json_body["envelope"]["envelope_id"]
  end

  test "embedded_signing_session returns url and resolves relative return_url" do
    Docusign::RecipientViewService.stubs(:call).returns("https://docusign.example.com/sign")
    post "/t/acme/contracts/#{@acme_contract.id}/embedded_signing_session", params: {
      signer_email: @acme_primary_signer.email,
      return_url: "/done"
    }, as: :json

    assert_response :success
    assert_equal "https://docusign.example.com/sign", json_body["signing_url"]
    assert_equal "http://www.example.com/done", json_body["return_url"]
  end

  test "embedded_signing_session returns bad request when signer_email missing" do
    post "/t/acme/contracts/#{@acme_contract.id}/embedded_signing_session", as: :json

    assert_response :bad_request
    assert_match "param is missing", json_body["error"]
  end
end
