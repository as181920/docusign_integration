require "test_helper"

class TenantDocusignTemplateSyncsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    create(:tenant_docusign_connection, :acme_connection, tenant: @tenant, connected_by_tenant_user: @tenant_user)

    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @tenant_user.name)
  end

  test "create syncs templates and redirects to template list for html" do
    Docusign::TemplateSyncService.stubs(:call).returns(
      total_count: 3,
      created_count: 2,
      updated_count: 1,
      skipped_count: 0
    )

    assert_difference "AuditLog.count", +1 do
      post "/t/acme/docusign_template_sync"
    end

    assert_response :redirect
    assert_redirected_to "/t/acme/contract_templates"
    follow_redirect!

    assert_match "模板同步完成：共 3 条，新建 2 条，更新 1 条，跳过 0 条", response.body
  end

  test "create returns sync result for json" do
    Docusign::TemplateSyncService.stubs(:call).returns(
      total_count: 5,
      created_count: 4,
      updated_count: 1,
      skipped_count: 0
    )

    post "/t/acme/docusign_template_sync.json"

    assert_response :success
    assert_equal 5, json_body["total_count"]
    assert_equal 4, json_body["created_count"]
    assert_equal 1, json_body["updated_count"]
  end

  test "create returns unprocessable when sync fails" do
    Docusign::TemplateSyncService.stubs(:call).raises(Docusign::ApiError.new("sync failed"))

    post "/t/acme/docusign_template_sync.json"

    assert_response :unprocessable_entity
    assert_match "sync failed", json_body["error"]
  end
end
