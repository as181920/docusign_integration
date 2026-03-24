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

  test "create from local template copies default signer and metadata" do
    local_template = create_local_template_for_contract_copy

    post "/t/acme/contracts", params: {
      contract: {
        title: "Offer Contract",
        contract_no: "C-ACME-NEW-LOCAL-001",
        contract_template_id: local_template.id
      }
    }, as: :json

    assert_response :created
    contract = Contract.find(json_body["id"])

    assert_nil contract.docusign_template_id
    assert_equal local_template.id, contract.metadata["contract_template_id"]
    assert_equal 1, contract.contract_signers.count
    assert_equal "demo.employee@example.com", contract.contract_signers.first.email
  end

  test "create from local template copies template documents to contract" do
    local_template = create_local_template_for_contract_copy

    post "/t/acme/contracts", params: {
      contract: {
        title: "Offer Contract",
        contract_no: "C-ACME-NEW-LOCAL-002",
        contract_template_id: local_template.id
      }
    }, as: :json

    assert_response :created
    contract = Contract.find(json_body["id"])

    assert_predicate contract.documents, :attached?
    assert_equal "contract.pdf", contract.documents.first.filename.to_s
  end

  test "create accepts manual contract document upload" do
    upload = Rack::Test::UploadedFile.new(file_fixture("contract.pdf"), "application/pdf")

    post "/t/acme/contracts", params: {
      contract: {
        title: "Manual Upload Contract",
        contract_no: "C-ACME-MANUAL-001",
        documents: [upload]
      }
    }

    assert_response :redirect
    contract = Contract.order(:id).last

    assert_equal "Manual Upload Contract", contract.title
    assert_predicate contract.documents, :attached?
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

  test "embedded_signing_session html redirects with short reference" do
    Docusign::RecipientViewService.stubs(:call).returns("https://docusign.example.com/sign")

    post "/t/acme/contracts/#{@acme_contract.id}/embedded_signing_session", params: {
      signer_email: @acme_primary_signer.email
    }

    assert_response :redirect

    redirect_uri = URI.parse(response.location)
    ref = Rack::Utils.parse_query(redirect_uri.query)["embedded_signing_ref"]

    assert_predicate ref, :present?
    assert_operator ref.length, :<=, 40
    refute_includes response.location, "docusign.example.com/sign"
  end

  test "embedded_signing_session returns bad request when signer_email missing" do
    post "/t/acme/contracts/#{@acme_contract.id}/embedded_signing_session", as: :json

    assert_response :bad_request
    assert_match "param is missing", json_body["error"]
  end

  private

    def create_local_template_for_contract_copy
      local_template = create(
        :contract_template,
        tenant: @acme_tenant,
        name: "Offer Template",
        version: 1,
        docusign_template_id: nil,
        publish_state: :draft
      )
      create(
        :contract_template_role,
        contract_template: local_template,
        role_name: "Employee",
        signer_name: "Demo Employee",
        signer_email: "demo.employee@example.com",
        routing_order: 1,
        signing_type: :signer
      )
      local_template.documents.attach(
        io: file_fixture("contract.pdf").open,
        filename: "contract.pdf",
        content_type: "application/pdf"
      )
      local_template
    end
end
