require "test_helper"

class TenantWebhookEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @acme_tenant = create(:tenant, :acme)
    @acme_user = create(:tenant_user, :alice, tenant: @acme_tenant)
    @acme_event = create(
      :webhook_event,
      tenant: @acme_tenant,
      delivery_id: "delivery-acme-001",
      event_type: "envelope-completed",
      external_event_id: "env-acme-001",
      payload: { "data" => { "accountId" => "acct_acme" } }
    )

    @beta_tenant = create(:tenant, :beta)
    @beta_user = create(:tenant_user, :bob, tenant: @beta_tenant)
    @beta_event = create(:webhook_event, tenant: @beta_tenant, delivery_id: "delivery-beta-001")

    sign_in_tenant_user(tenant_uid: @acme_tenant.uid, name: @acme_user.name)
  end

  test "index renders current tenant webhook events" do
    get "/t/acme/webhook_events"

    assert_response :success
    assert_match("delivery-acme-001", response.body)
    assert_no_match("delivery-beta-001", response.body)
  end

  test "index supports pagination" do
    create_list(:webhook_event, 25, tenant: @acme_tenant, provider: "docusign")

    get "/t/acme/webhook_events", params: { per: 10 }, as: :json

    assert_response :success
    assert_equal 10, json_body.size
  end

  test "index supports ransack filtering" do
    create(:webhook_event, tenant: @acme_tenant, delivery_id: "filter-target-001", event_type: "envelope-sent")

    get "/t/acme/webhook_events", params: {
      q: { event_type_or_delivery_id_or_external_event_id_cont: "filter-target-001" }
    }, as: :json

    assert_response :success
    assert_operator json_body.size, :>=, 1
    assert json_body.all? { |row| "#{row['event_type']} #{row['delivery_id']} #{row['external_event_id']}".include?("filter-target-001") }
  end

  test "index recent statistics follow recent_days window" do
    create(:webhook_event, tenant: @acme_tenant, delivery_id: "delivery-old-001", received_at: 15.days.ago)

    get "/t/acme/webhook_events", params: { recent_days: 7 }

    assert_response :success
    assert_match("最近 7 天 1 条", response.body)

    get "/t/acme/webhook_events", params: { recent_days: 30 }

    assert_response :success
    assert_match("最近 30 天 2 条", response.body)
  end

  test "index returns only current tenant events in json" do
    get "/t/acme/webhook_events.json"

    assert_response :success
    ids = json_body.map { |row| row["id"] }

    assert_includes ids, @acme_event.id
    assert_not_includes ids, @beta_event.id
  end

  test "show renders webhook event detail" do
    get "/t/acme/webhook_events/#{@acme_event.id}"

    assert_response :success
    assert_match("Webhook 事件详情", response.body)
    assert_match("delivery-acme-001", response.body)
    assert_match("acct_acme", response.body)
  end

  test "show rejects webhook event from another tenant" do
    get "/t/acme/webhook_events/#{@beta_event.id}"

    assert_response :not_found
  end
end
