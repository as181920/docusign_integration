# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_12_210000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "aato_taggings", force: :cascade do |t|
    t.string "context", limit: 128
    t.datetime "created_at"
    t.bigint "tag_id"
    t.bigint "taggable_id"
    t.string "taggable_type"
    t.bigint "tagger_id"
    t.string "tagger_type"
    t.index ["context"], name: "index_aato_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_aato_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "taggings_taggable_context_idx"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_type", "taggable_id"], name: "index_aato_taggings_on_taggable"
    t.index ["tagger_id", "tagger_type"], name: "index_aato_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_type", "tagger_id"], name: "index_aato_taggings_on_tagger"
  end

  create_table "aato_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "taggings_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_aato_tags_on_name", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "anon_access_codes", force: :cascade do |t|
    t.bigint "accessible_id"
    t.string "accessible_type"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "updated_at", null: false
    t.index ["accessible_type", "accessible_id"], name: "index_anon_access_codes_on_accessible"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.string "actor_type"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "ip"
    t.string "request_id"
    t.bigint "target_id"
    t.string "target_type"
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["action", "created_at"], name: "index_audit_logs_on_action_and_created_at"
    t.index ["actor_type", "actor_id"], name: "index_audit_logs_on_actor_type_and_actor_id"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target_type_and_target_id"
    t.index ["tenant_id"], name: "index_audit_logs_on_tenant_id"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.jsonb "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "contract_envelopes", force: :cascade do |t|
    t.datetime "completed_at"
    t.bigint "contract_id", null: false
    t.datetime "created_at", null: false
    t.datetime "declined_at"
    t.string "envelope_id", null: false
    t.datetime "last_synced_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "sent_at"
    t.string "status", default: "created", null: false
    t.bigint "tenant_docusign_connection_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "voided_at"
    t.index ["contract_id"], name: "index_contract_envelopes_on_contract_id", unique: true
    t.index ["envelope_id"], name: "index_contract_envelopes_on_envelope_id", unique: true
    t.index ["tenant_docusign_connection_id"], name: "index_contract_envelopes_on_tenant_docusign_connection_id"
  end

  create_table "contract_signers", force: :cascade do |t|
    t.bigint "contract_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "role_name", null: false
    t.integer "routing_order", default: 1, null: false
    t.string "signing_type", default: "signer", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id", "email", "role_name"], name: "index_contract_signers_on_contract_id_and_email_and_role_name", unique: true
    t.index ["contract_id"], name: "index_contract_signers_on_contract_id"
  end

  create_table "contract_template_roles", force: :cascade do |t|
    t.bigint "contract_template_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "role_name", null: false
    t.integer "routing_order", default: 1, null: false
    t.string "signer_email"
    t.string "signer_name"
    t.string "signing_type", default: "signer", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_template_id", "role_name", "signing_type"], name: "idx_contract_template_roles_on_template_role_and_type", unique: true
    t.index ["contract_template_id"], name: "index_contract_template_roles_on_contract_template_id"
  end

  create_table "contract_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "docusign_template_id"
    t.text "email_message"
    t.string "email_subject"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "publish_state", default: "draft", null: false
    t.datetime "published_at"
    t.string "status", default: "active", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version", default: 1, null: false
    t.index ["tenant_id", "name", "status"], name: "index_contract_templates_on_tenant_id_and_name_and_status"
    t.index ["tenant_id", "name", "version"], name: "index_contract_templates_on_tenant_id_and_name_and_version", unique: true
    t.index ["tenant_id", "publish_state"], name: "index_contract_templates_on_tenant_id_and_publish_state"
    t.index ["tenant_id"], name: "index_contract_templates_on_tenant_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.datetime "completed_at"
    t.string "contract_no", null: false
    t.datetime "created_at", null: false
    t.bigint "creator_tenant_user_id"
    t.string "currency", default: "USD", null: false
    t.string "docusign_template_id"
    t.string "language", default: "en", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "sent_at"
    t.string "source", default: "manual", null: false
    t.string "status", default: "draft", null: false
    t.bigint "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "contract_no"], name: "index_contracts_on_tenant_id_and_contract_no", unique: true
    t.index ["tenant_id"], name: "index_contracts_on_tenant_id"
  end

  create_table "external_identities", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name"
    t.string "open_id"
    t.string "provider", null: false
    t.string "provider_uid", null: false
    t.bigint "tenant_id", null: false
    t.bigint "tenant_user_id"
    t.string "union_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tenant_id", "provider", "open_id"], name: "idx_on_tenant_id_provider_open_id_65df6e15f7", unique: true, where: "(open_id IS NOT NULL)"
    t.index ["tenant_id", "provider", "provider_uid"], name: "idx_on_tenant_id_provider_provider_uid_15e07ee3a7", unique: true
    t.index ["tenant_id", "provider", "union_id"], name: "idx_on_tenant_id_provider_union_id_19f1f5f37c", unique: true, where: "(union_id IS NOT NULL)"
    t.index ["tenant_id"], name: "index_external_identities_on_tenant_id"
    t.index ["tenant_user_id"], name: "index_external_identities_on_tenant_user_id"
    t.index ["user_id"], name: "index_external_identities_on_user_id"
  end

  create_table "feishu_enterprises", force: :cascade do |t|
    t.string "app_encrypt_key"
    t.string "app_id"
    t.string "app_secret"
    t.string "app_verification_token"
    t.datetime "created_at", null: false
    t.string "name"
    t.jsonb "raw_payload", default: {}, null: false
    t.string "status", default: "active", null: false
    t.bigint "tenant_id", null: false
    t.string "tenant_key"
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_feishu_enterprises_on_tenant_id", unique: true
    t.index ["tenant_key"], name: "index_feishu_enterprises_on_tenant_key", unique: true
  end

  create_table "omni_account_accounts", force: :cascade do |t|
    t.decimal "balance", precision: 18, scale: 2, default: "0.0", null: false
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.bigint "holder_id"
    t.string "holder_type"
    t.string "name"
    t.integer "normal_balance"
    t.bigint "parent_id"
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "allow_contra_balance"
    t.index ["holder_id", "holder_type", "name"], name: "index_omni_account_accounts_on_holder_and_name", unique: true
    t.index ["normal_balance"], name: "index_omni_account_accounts_on_normal_balance"
    t.index ["parent_id"], name: "index_omni_account_accounts_on_parent_id"
  end

  create_table "omni_account_entries", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.bigint "origin_id"
    t.string "origin_type"
    t.string "uid"
    t.index ["origin_type", "origin_id"], name: "index_omni_account_entries_on_origin_type_and_origin_id"
    t.index ["uid"], name: "index_omni_account_entries_on_uid", unique: true
  end

  create_table "omni_account_postings", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "amount", precision: 18, scale: 2, null: false
    t.decimal "balance", precision: 18, scale: 2, null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.bigint "entry_id"
    t.bigint "previous_id"
    t.index ["account_id"], name: "index_omni_account_postings_on_account_id"
    t.index ["entry_id"], name: "index_omni_account_postings_on_entry_id"
    t.index ["previous_id", "account_id"], name: "index_omni_account_postings_on_previous_and_account", unique: true
  end

  create_table "omni_pay_notification_recipients", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.bigint "user_id"
    t.integer "state"
    t.text "remark"
    t.jsonb "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "user_id"], name: "index_omni_pay_notification_recipients_on_owner_and_user", unique: true
    t.index ["owner_type", "owner_id"], name: "index_omni_pay_notification_recipients_on_owner"
    t.index ["user_id"], name: "index_omni_pay_notification_recipients_on_user"
  end

  create_table "omni_pay_payment_methods", force: :cascade do |t|
    t.boolean "active"
    t.integer "channel_type"
    t.datetime "created_at", null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.integer "position"
    t.jsonb "settings"
    t.datetime "updated_at", null: false
    t.string "label"
    t.index ["owner_type", "owner_id"], name: "index_omni_pay_payment_methods_on_owner"
  end

  create_table "omni_pay_payment_requests", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "source_type"
    t.bigint "source_id"
    t.string "created_by_type"
    t.bigint "created_by_id"
    t.string "uid"
    t.string "title"
    t.decimal "amount", precision: 12, scale: 2
    t.integer "state"
    t.datetime "expires_at", precision: nil
    t.datetime "paid_at", precision: nil
    t.jsonb "display_data"
    t.jsonb "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_type", "created_by_id"], name: "index_omni_pay_payment_requests_on_created_by"
    t.index ["owner_type", "owner_id"], name: "index_omni_pay_payment_requests_on_owner"
    t.index ["source_type", "source_id"], name: "index_omni_pay_payment_requests_on_source"
    t.index ["uid"], name: "index_omni_pay_payment_requests_on_uid", unique: true
  end

  create_table "omni_pay_payments", force: :cascade do |t|
    t.bigint "payment_request_id"
    t.bigint "payment_method_id"
    t.string "payer_type"
    t.bigint "payer_id"
    t.string "uid"
    t.integer "state"
    t.decimal "amount", precision: 12, scale: 2
    t.string "pay_scene"
    t.datetime "paid_at", precision: nil
    t.datetime "closed_at", precision: nil
    t.jsonb "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payer_type", "payer_id"], name: "index_omni_pay_payments_on_payer"
    t.index ["payment_method_id"], name: "index_omni_pay_payments_on_payment_method_id"
    t.index ["payment_request_id"], name: "index_omni_pay_payments_on_payment_request_id"
    t.index ["uid"], name: "index_omni_pay_payments_on_uid", unique: true
  end

  create_table "omni_pay_refunds", force: :cascade do |t|
    t.bigint "payment_id"
    t.string "requested_by_type"
    t.bigint "requested_by_id"
    t.string "uid"
    t.integer "state"
    t.decimal "amount", precision: 12, scale: 2
    t.text "description"
    t.datetime "success_at", precision: nil
    t.jsonb "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["payment_id"], name: "index_omni_pay_refunds_on_payment_id"
    t.index ["requested_by_type", "requested_by_id"], name: "index_omni_pay_refunds_on_requested_by"
    t.index ["uid"], name: "index_omni_pay_refunds_on_uid", unique: true
  end

  create_table "omni_region_divisions", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.bigint "parent_id"
    t.string "type"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["code"], name: "index_omni_region_divisions_on_code", unique: true
    t.index ["parent_id"], name: "index_omni_region_divisions_on_parent_id"
  end

  create_table "omni_role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_omni_role_permissions_on_name", unique: true
  end

  create_table "omni_role_permissions_roles", force: :cascade do |t|
    t.bigint "permission_id"
    t.bigint "role_id"
    t.index ["permission_id"], name: "index_omni_role_permissions_roles_on_permission_id"
    t.index ["role_id"], name: "index_omni_role_permissions_roles_on_role_id"
  end

  create_table "omni_role_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["resource_type", "resource_id", "name"], name: "index_omni_role_roles_on_resource_and_name", unique: true
    t.index ["resource_type", "resource_id"], name: "index_omni_role_roles_on_resource"
  end

  create_table "omni_role_user_role_maps", force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.string "user_type"
    t.index ["role_id"], name: "index_omni_role_user_role_maps_on_role_id"
    t.index ["user_type", "user_id"], name: "index_omni_role_user_role_maps_on_user"
  end

  create_table "org_content_entries", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "entry_name"
    t.bigint "organization_id"
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "entry_name"], name: "index_org_content_entry_on_org_and_name"
    t.index ["organization_id"], name: "index_org_content_entries_on_organization_id"
  end

  create_table "org_departments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "depth", default: 0, null: false
    t.integer "lft", null: false
    t.string "name"
    t.bigint "organization_id"
    t.integer "parent_id"
    t.integer "rgt", null: false
    t.datetime "updated_at", null: false
    t.index ["lft"], name: "index_org_departments_on_lft"
    t.index ["organization_id", "name"], name: "index_org_departments_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_org_departments_on_organization_id"
    t.index ["parent_id"], name: "index_org_departments_on_parent_id"
    t.index ["rgt"], name: "index_org_departments_on_rgt"
  end

  create_table "org_organization_wechat_official_account_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "wechat_official_account_id", null: false
    t.index ["organization_id"], name: "index_org_organization_wechat_oa_mappings_on_org", unique: true
    t.index ["wechat_official_account_id"], name: "index_org_organization_wechat_oa_mappings_on_wechat_oa"
  end

  create_table "org_organization_wechat_sp_vendor_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "wechat_sp_vendor_id", null: false
    t.index ["organization_id"], name: "index_org_organization_wechat_sp_vendor_mappings_on_org", unique: true
    t.index ["wechat_sp_vendor_id"], name: "index_org_organization_wechat_sp_vendor_mappings_on_vendor"
  end

  create_table "org_organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "custom_settings", default: {}
    t.string "name", null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_org_organizations_on_name", unique: true
    t.index ["uid"], name: "index_org_organizations_on_uid", unique: true
  end

  create_table "org_phones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "number"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["number"], name: "index_org_phones_on_number", unique: true
    t.index ["user_id"], name: "index_org_phones_on_user_id", unique: true
  end

  create_table "org_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "custom_settings"
    t.datetime "last_sign_in_at"
    t.string "locale"
    t.string "nickname"
    t.string "otp_key"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_org_profiles_on_user_id", unique: true
  end

  create_table "org_user_credentials", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["code"], name: "index_org_user_credentials_on_code", unique: true
    t.index ["token"], name: "index_org_user_credentials_on_token", unique: true
    t.index ["user_id"], name: "index_org_user_credentials_on_user_id"
  end

  create_table "org_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "department_id"
    t.string "name"
    t.bigint "organization_id", null: false
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.boolean "root"
    t.index ["department_id"], name: "index_org_users_on_department_id"
    t.index ["name"], name: "index_org_users_on_name", unique: true, where: "(root = true)"
    t.index ["organization_id", "name"], name: "index_org_users_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_org_users_on_organization_id"
    t.index ["organization_id"], name: "index_org_users_on_organization_id_where_root", unique: true, where: "(root = true)"
  end

  create_table "outbound_events", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "dispatched_at"
    t.string "event_name", null: false
    t.text "last_error"
    t.jsonb "payload", default: {}, null: false
    t.bigint "source_id"
    t.string "source_type"
    t.string "status", default: "pending", null: false
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["source_type", "source_id"], name: "index_outbound_events_on_source_type_and_source_id"
    t.index ["status", "created_at"], name: "index_outbound_events_on_status_and_created_at"
    t.index ["tenant_id"], name: "index_outbound_events_on_tenant_id"
  end

  create_table "owx_message_handlers", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "official_account_id"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["official_account_id"], name: "index_owx_message_handlers_on_official_account_id", unique: true
  end

  create_table "owx_official_accounts", force: :cascade do |t|
    t.string "alias"
    t.string "app_id"
    t.jsonb "business_info"
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "func_info"
    t.string "head_img"
    t.jsonb "mini_program_info"
    t.string "nick_name"
    t.bigint "open_account_id"
    t.string "original_id"
    t.string "principal_name"
    t.string "qrcode_url"
    t.string "refresh_token"
    t.jsonb "service_type_info"
    t.string "signature"
    t.bigint "third_party_platform_id"
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "verify_type_info"
    t.index ["open_account_id"], name: "index_owx_official_accounts_on_open_account_id"
    t.index ["third_party_platform_id", "app_id"], name: "index_owx_official_accounts_on_platform_and_app_id", unique: true
    t.index ["third_party_platform_id", "original_id"], name: "index_owx_official_accounts_on_platform_and_original_id", unique: true
    t.index ["third_party_platform_id"], name: "index_owx_official_accounts_on_third_party_platform_id"
  end

  create_table "owx_open_accounts", force: :cascade do |t|
    t.string "app_id"
    t.datetime "created_at", null: false
    t.string "principal_name"
    t.bigint "third_party_platform_id"
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_owx_open_accounts_on_app_id", unique: true
    t.index ["principal_name"], name: "index_owx_open_accounts_on_principal_name", unique: true
    t.index ["third_party_platform_id"], name: "index_owx_open_accounts_on_third_party_platform_id"
  end

  create_table "owx_third_party_platforms", force: :cascade do |t|
    t.string "app_id"
    t.string "app_secret"
    t.datetime "created_at", precision: nil, null: false
    t.string "message_encryption_key"
    t.string "messages_checking_token"
    t.string "name"
    t.string "uid"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["app_id"], name: "index_owx_third_party_platforms_on_app_id", unique: true
    t.index ["uid"], name: "index_owx_third_party_platforms_on_uid", unique: true
  end

  create_table "owx_verify_files", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_owx_verify_files_on_name", unique: true
  end

  create_table "owx_website_apps", force: :cascade do |t|
    t.string "app_id"
    t.string "app_secret"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_owx_website_apps_on_app_id", unique: true
  end

  create_table "short_url_links", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "original_url"
    t.index ["original_url"], name: "index_short_url_links_on_original_url", unique: true
  end

  create_table "tenant_docusign_connections", force: :cascade do |t|
    t.text "access_token"
    t.datetime "connected_at"
    t.bigint "connected_by_tenant_user_id"
    t.datetime "created_at", null: false
    t.string "docusign_account_id", null: false
    t.string "docusign_base_uri"
    t.jsonb "metadata", default: {}, null: false
    t.string "oauth_scope", default: "signature", null: false
    t.text "refresh_token"
    t.string "status", default: "active", null: false
    t.bigint "tenant_id", null: false
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.index ["docusign_account_id"], name: "index_tenant_docusign_connections_on_docusign_account_id", unique: true
    t.index ["tenant_id"], name: "index_tenant_docusign_connections_on_tenant_id", unique: true
  end

  create_table "tnt_domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.string "wechat_app_id"
    t.string "wechat_app_secret"
    t.index ["tenant_id"], name: "index_tnt_domains_on_tenant_id", unique: true
  end

  create_table "tnt_fund_transfers", force: :cascade do |t|
    t.decimal "amount", precision: 2, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "state"
    t.bigint "tenant_id"
    t.bigint "transfer_in_account_id"
    t.bigint "transfer_out_account_id"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_tnt_fund_transfers_on_tenant_id"
    t.index ["transfer_in_account_id"], name: "index_tnt_fund_transfers_on_transfer_in_account_id"
    t.index ["transfer_out_account_id"], name: "index_tnt_fund_transfers_on_transfer_out_account_id"
    t.index ["uid"], name: "index_tnt_fund_transfers_on_uid", unique: true
  end

  create_table "tnt_impersonations", force: :cascade do |t|
    t.bigint "tenant_id"
    t.string "actor_type"
    t.bigint "actor_id"
    t.bigint "target_user_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "expires_at"
    t.string "started_ip"
    t.string "ended_ip"
    t.text "user_agent"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id", "ended_at"], name: "idx_on_actor_type_actor_id_ended_at_da7d110a23"
    t.index ["target_user_id", "ended_at"], name: "index_tnt_impersonations_on_target_user_id_and_ended_at"
  end

  create_table "tnt_phones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "number"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["number"], name: "index_tnt_phones_on_number", unique: true
    t.index ["user_id"], name: "index_tnt_phones_on_user_id", unique: true
  end

  create_table "tnt_profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "custom_settings", default: {}
    t.datetime "last_sign_in_at"
    t.string "locale"
    t.string "nickname"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_tnt_profiles_on_user_id", unique: true
  end

  create_table "tnt_recharges", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.jsonb "properties"
    t.integer "state"
    t.bigint "tenant_id", null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_tnt_recharges_on_tenant_id"
    t.index ["uid"], name: "index_tnt_recharges_on_uid", unique: true
  end

  create_table "tnt_tenant_ext_infos", force: :cascade do |t|
    t.string "content_quick_tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "implicit_auth_mode"
    t.string "permissions", default: [], array: true
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.integer "wechat_oauth_scope"
    t.index ["tenant_id"], name: "index_tnt_tenant_ext_infos_on_tenant_id", unique: true
  end

  create_table "tnt_tenant_wechat_official_account_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "wechat_official_account_id", null: false
    t.index ["tenant_id"], name: "index_tnt_tenant_wechat_oa_mapping_on_tennat", unique: true
    t.index ["wechat_official_account_id"], name: "index_tnt_tenant_wechat_oa_mapping_on_wechat_oa"
  end

  create_table "tnt_tenant_wechat_work_corporation_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "wechat_work_corporation_id", null: false
    t.index ["tenant_id"], name: "index_tnt_tenant_wecom_corp_mapping_on_tennat", unique: true
    t.index ["wechat_work_corporation_id"], name: "index_tnt_tenant_wecom_corp_mapping_on_corp"
  end

  create_table "tnt_tenants", force: :cascade do |t|
    t.bigint "agency_id"
    t.datetime "created_at", null: false
    t.jsonb "custom_settings", default: {}
    t.string "name"
    t.bigint "organization_id", null: false
    t.integer "state"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_tnt_tenants_on_agency_id"
    t.index ["name"], name: "index_tnt_tenants_on_name", unique: true
    t.index ["organization_id"], name: "index_tnt_tenants_on_organization_id"
    t.index ["uid"], name: "index_tnt_tenants_on_uid", unique: true
  end

  create_table "tnt_user_credentials", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["code"], name: "index_tnt_user_credentials_on_code", unique: true
    t.index ["token"], name: "index_tnt_user_credentials_on_token", unique: true
    t.index ["user_id"], name: "index_tnt_user_credentials_on_user_id"
  end

  create_table "tnt_user_notification_preferences", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "channel"
    t.boolean "enabled"
    t.jsonb "enabled_topics"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "channel"], name: "idx_tnt_user_notification_preferences_unique", unique: true
  end

  create_table "tnt_user_wechat_user_mappings", force: :cascade do |t|
    t.bigint "tenant_id"
    t.bigint "user_id"
    t.bigint "wechat_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "wechat_user_id"], name: "idx_tnt_user_wechat_user_mappings_identity", unique: true
    t.index ["user_id"], name: "index_tnt_user_wechat_user_mappings_on_user_id", unique: true
  end

  create_table "tnt_user_wechat_work_user_mappings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "wechat_work_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tnt_user_wechat_work_user_mappings_on_user_id", unique: true
    t.index ["wechat_work_user_id"], name: "idx_on_wechat_work_user_id_3760b0abb6", unique: true
  end

  create_table "tnt_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "password_digest"
    t.boolean "root"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.integer "state"
    t.index ["name"], name: "index_tnt_users_on_name", unique: true, where: "(root = true)"
    t.index ["tenant_id", "name"], name: "index_tnt_users_on_tenant_id_and_name", unique: true
    t.index ["tenant_id", "state"], name: "index_tnt_users_on_tenant_id_and_state"
    t.index ["tenant_id"], name: "index_tnt_users_on_tenant_id"
  end

  create_table "tnt_withdraw_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "custom_settings", default: {}
    t.integer "payment_method"
    t.string "real_name"
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_tnt_withdraw_settings_on_tenant_id", unique: true
  end

  create_table "tnt_withdrawals", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "state"
    t.bigint "tenant_id", null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_tnt_withdrawals_on_account_id"
    t.index ["tenant_id"], name: "index_tnt_withdrawals_on_tenant_id"
    t.index ["uid"], name: "index_tnt_withdrawals_on_uid", unique: true
  end

  create_table "usr_delivery_addresses", force: :cascade do |t|
    t.bigint "user_id"
    t.string "consignee_name"
    t.string "consignee_tel"
    t.string "province_code"
    t.string "city_code"
    t.string "district_code"
    t.string "location_name"
    t.text "detail_info"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.boolean "default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_usr_delivery_addresses_on_user_id"
  end

  create_table "usr_emails", force: :cascade do |t|
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_usr_emails_on_address", unique: true
  end

  create_table "usr_identity_cards", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.jsonb "custom_settings"
    t.integer "state"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_usr_identity_cards_on_code", unique: true
    t.index ["uid"], name: "index_usr_identity_cards_on_uid", unique: true
  end

  create_table "usr_locations", force: :cascade do |t|
    t.float "accuracy"
    t.string "address"
    t.string "city"
    t.string "coordinate_type"
    t.datetime "created_at", null: false
    t.string "district"
    t.string "division_code"
    t.float "latitude"
    t.float "longitude"
    t.string "province"
    t.float "speed"
    t.string "street"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_usr_locations_on_user_id"
  end

  create_table "usr_phones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "number", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_usr_phones_on_number", unique: true
  end

  create_table "usr_profiles", force: :cascade do |t|
    t.date "birthday"
    t.datetime "created_at", null: false
    t.jsonb "custom_settings"
    t.integer "gender"
    t.datetime "last_sign_in_at"
    t.string "locale"
    t.string "nickname"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_usr_profiles_on_user_id", unique: true
  end

  create_table "usr_shipping_addresses", force: :cascade do |t|
    t.string "city_code"
    t.string "consignee_name"
    t.string "consignee_tel"
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "detail_info"
    t.string "district_code"
    t.string "postal_code"
    t.string "province_code"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_usr_shipping_addresses_on_user_id"
  end

  create_table "usr_user_credentials", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["code"], name: "index_usr_user_credentials_on_code", unique: true
    t.index ["token"], name: "index_usr_user_credentials_on_token", unique: true
    t.index ["user_id"], name: "index_usr_user_credentials_on_user_id"
  end

  create_table "usr_user_delegations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "custom_settings"
    t.bigint "principal_user_id"
    t.bigint "target_user_id"
    t.datetime "updated_at", null: false
    t.index ["principal_user_id", "target_user_id"], name: "index_usr_user_delegations_on_principal_and_target", unique: true
    t.index ["principal_user_id"], name: "index_usr_user_delegations_on_principal_user_id"
    t.index ["target_user_id"], name: "index_usr_user_delegations_on_target_user_id"
  end

  create_table "usr_user_origins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "origin_id"
    t.string "origin_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["origin_type", "origin_id"], name: "index_usr_user_origins_on_origin"
    t.index ["user_id", "origin_id", "origin_type"], name: "index_usr_user_origins_on_user_and_origin", unique: true
    t.index ["user_id"], name: "index_usr_user_origins_on_user_id"
  end

  create_table "usr_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "password_digest"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_usr_users_on_name", unique: true
    t.index ["uid"], name: "index_usr_users_on_uid", unique: true
  end

  create_table "usr_wechat_users", force: :cascade do |t|
    t.string "app_id"
    t.string "auth_scope"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "nickname"
    t.string "open_id", null: false
    t.string "refresh_token"
    t.boolean "subscribe"
    t.string "subscribe_scene"
    t.datetime "subscribed_at", precision: nil
    t.string "union_id"
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_usr_wechat_users_on_app_id"
    t.index ["open_id"], name: "index_usr_wechat_users_on_open_id", unique: true
    t.index ["union_id"], name: "index_usr_wechat_users_on_union_id"
  end

  create_table "usr_withdrawals", force: :cascade do |t|
    t.bigint "account_id"
    t.decimal "amount", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "state"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_usr_withdrawals_on_account_id"
    t.index ["uid"], name: "index_usr_withdrawals_on_uid", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "delivery_id", null: false
    t.string "event_type"
    t.string "external_account_id"
    t.string "external_event_id"
    t.jsonb "headers", default: {}, null: false
    t.text "last_error"
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.integer "processing_attempts", default: 0, null: false
    t.string "provider", default: "docusign", null: false
    t.datetime "received_at"
    t.string "status", default: "received", null: false
    t.bigint "tenant_id"
    t.datetime "updated_at", null: false
    t.index ["provider", "delivery_id"], name: "index_webhook_events_on_provider_and_delivery_id", unique: true
    t.index ["provider", "external_account_id"], name: "index_webhook_events_on_provider_and_external_account_id"
    t.index ["status", "created_at"], name: "index_webhook_events_on_status_and_created_at"
    t.index ["tenant_id"], name: "index_webhook_events_on_tenant_id"
  end

  create_table "wxpay_api_client_certificates", force: :cascade do |t|
    t.text "cert"
    t.datetime "created_at", null: false
    t.datetime "effective_at"
    t.datetime "expire_at"
    t.text "key"
    t.string "serial_no"
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["vendor_id"], name: "index_wxpay_api_client_certificates_on_vendor_id"
  end

  create_table "wxpay_busifavor_coupons", force: :cascade do |t|
    t.string "app_id"
    t.datetime "available_start_time"
    t.string "code"
    t.string "comment"
    t.jsonb "coupon_use_rule"
    t.datetime "created_at", null: false
    t.string "deactivate_reason"
    t.string "deactivate_request_no"
    t.datetime "deactivate_time"
    t.datetime "expire_time"
    t.string "goods_name"
    t.string "open_id"
    t.bigint "origin_id"
    t.string "origin_type"
    t.datetime "receive_time"
    t.string "return_request_no"
    t.datetime "return_time"
    t.string "send_request_no"
    t.integer "state"
    t.string "stock_id"
    t.string "stock_name"
    t.integer "stock_type"
    t.datetime "updated_at", null: false
    t.string "use_request_no"
    t.datetime "use_time"
    t.index ["code"], name: "index_wxpay_busifavor_coupons_on_code", unique: true
    t.index ["origin_type", "origin_id"], name: "index_wxpay_busifavor_coupons_on_origin", unique: true
    t.index ["send_request_no"], name: "index_wxpay_busifavor_coupons_on_send_request_no", unique: true
    t.index ["stock_id"], name: "index_wxpay_busifavor_coupons_on_stock_id"
    t.index ["use_request_no"], name: "index_wxpay_busifavor_coupons_on_use_request_no", unique: true
  end

  create_table "wxpay_busifavor_stocks", force: :cascade do |t|
    t.string "belong_merchant"
    t.string "comment"
    t.integer "coupon_code_mode"
    t.jsonb "coupon_use_rule"
    t.datetime "created_at", null: false
    t.jsonb "custom_entrance"
    t.jsonb "display_pattern_info"
    t.string "goods_name"
    t.jsonb "notify_config"
    t.bigint "origin_id"
    t.string "origin_type"
    t.string "out_request_no"
    t.jsonb "send_count_information"
    t.integer "state"
    t.string "stock_id"
    t.string "stock_name"
    t.jsonb "stock_send_rule"
    t.integer "stock_type"
    t.datetime "updated_at", null: false
    t.index ["belong_merchant"], name: "index_wxpay_busifavor_stocks_on_belong_merchant"
    t.index ["origin_type", "origin_id"], name: "index_wxpay_busifavor_stocks_on_origin", unique: true
    t.index ["out_request_no"], name: "index_wxpay_busifavor_stocks_on_out_request_no", unique: true
    t.index ["stock_id"], name: "index_wxpay_busifavor_stocks_on_stock_id", unique: true
  end

  create_table "wxpay_capital_bank_branches", force: :cascade do |t|
    t.string "bank_alias_code"
    t.string "bank_branch_id"
    t.string "bank_branch_name"
    t.string "city_code"
    t.string "city_name"
    t.datetime "created_at", null: false
    t.string "province_code"
    t.string "province_name"
    t.datetime "updated_at", null: false
    t.index ["bank_alias_code"], name: "index_wxpay_capital_bank_branches_on_bank_alias_code"
  end

  create_table "wxpay_capital_corporate_banks", force: :cascade do |t|
    t.string "account_bank"
    t.integer "account_bank_code"
    t.string "bank_alias"
    t.string "bank_alias_code"
    t.datetime "created_at", null: false
    t.boolean "need_bank_branch"
    t.datetime "updated_at", null: false
  end

  create_table "wxpay_capital_personal_banks", force: :cascade do |t|
    t.string "account_bank"
    t.integer "account_bank_code"
    t.string "bank_alias"
    t.string "bank_alias_code"
    t.datetime "created_at", null: false
    t.boolean "need_bank_branch"
    t.datetime "updated_at", null: false
  end

  create_table "wxpay_ecommerce_applyments", force: :cascade do |t|
    t.jsonb "account_info"
    t.jsonb "account_validation"
    t.string "applyment_id"
    t.jsonb "audit_detail"
    t.text "business_addition_desc"
    t.jsonb "business_addition_pics"
    t.jsonb "business_license_info"
    t.jsonb "contact_info"
    t.datetime "created_at", null: false
    t.jsonb "id_card_info"
    t.string "legal_validation_url"
    t.string "merchant_shortname"
    t.boolean "need_account_info"
    t.integer "organization_type"
    t.string "out_request_no"
    t.bigint "owner_id"
    t.string "owner_type"
    t.jsonb "qualifications"
    t.jsonb "sales_scene_info"
    t.string "sign_state"
    t.string "sign_url"
    t.integer "state"
    t.text "state_desc"
    t.string "sub_mch_id"
    t.datetime "updated_at", null: false
    t.index ["out_request_no"], name: "index_wxpay_ecommerce_applyments_on_out_request_no", unique: true
    t.index ["owner_type", "owner_id"], name: "index_wxpay_ecommerce_applyments_on_owner"
  end

  create_table "wxpay_partner_applyments", force: :cascade do |t|
    t.jsonb "addition_info"
    t.string "applyment_id"
    t.jsonb "audit_detail"
    t.jsonb "bank_account_info"
    t.string "business_code"
    t.jsonb "business_info"
    t.jsonb "contact_info"
    t.datetime "created_at", null: false
    t.bigint "owner_id"
    t.string "owner_type"
    t.jsonb "settlement_info"
    t.string "sign_url"
    t.integer "state"
    t.text "state_message"
    t.string "sub_mch_id"
    t.jsonb "subject_info"
    t.datetime "updated_at", null: false
    t.index ["business_code"], name: "index_wxpay_partner_applyments_on_business_code", unique: true
    t.index ["owner_type", "owner_id"], name: "index_wxpay_sub_applyments_on_owner"
  end

  create_table "wxpay_platform_certificates", force: :cascade do |t|
    t.text "cert"
    t.datetime "created_at", null: false
    t.datetime "effective_at"
    t.datetime "expire_at"
    t.string "serial_no"
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["vendor_id"], name: "index_wxpay_platform_certificates_on_vendor_id"
  end

  create_table "wxpay_profit_sharing_receivers", force: :cascade do |t|
    t.string "account"
    t.integer "account_type"
    t.string "app_id"
    t.datetime "created_at", null: false
    t.string "custom_relation"
    t.string "name"
    t.integer "relation_type"
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["account", "vendor_id", "app_id"], name: "index_wxpay_profit_sharing_receivers_on_vendor_app_account", unique: true
    t.index ["vendor_id"], name: "index_wxpay_profit_sharing_receivers_on_vendor_id"
  end

  create_table "wxpay_public_keys", force: :cascade do |t|
    t.bigint "vendor_id"
    t.string "key_id"
    t.text "pem"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["vendor_id", "key_id"], name: "index_wxpay_public_keys_on_vendor_id_and_key_id", unique: true
    t.index ["vendor_id"], name: "index_wxpay_public_keys_on_vendor_id"
  end

  create_table "wxpay_settlement_accounts", force: :cascade do |t|
    t.string "account_bank"
    t.string "account_number"
    t.string "account_type"
    t.string "bank_address_code"
    t.string "bank_branch_id"
    t.string "bank_name"
    t.datetime "created_at", null: false
    t.integer "state"
    t.string "sub_mch_id"
    t.datetime "updated_at", null: false
    t.text "verify_fail_reason"
    t.string "verify_result"
    t.index ["sub_mch_id"], name: "index_wxpay_settlement_accounts_on_sub_mch_id"
  end

  create_table "wxpay_vendors", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", precision: nil, null: false
    t.decimal "fee_rate", precision: 4, scale: 4
    t.string "mch_id"
    t.string "sp_mch_id"
    t.integer "type"
    t.datetime "updated_at", precision: nil, null: false
    t.string "v2_key"
    t.string "v3_key"
    t.index ["mch_id"], name: "index_wxpay_vendors_on_mch_id", unique: true
    t.index ["sp_mch_id"], name: "index_wxpay_vendors_on_sp_mch_id"
  end

  create_table "wxpay_verify_files", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_wxpay_verify_files_on_name", unique: true
  end

  create_table "wxwork_contact_ways", force: :cascade do |t|
    t.string "config_id"
    t.bigint "corporation_id"
    t.datetime "created_at", null: false
    t.boolean "is_temp", default: true, null: false
    t.integer "party", array: true
    t.string "qr_code"
    t.string "remark"
    t.integer "scene"
    t.boolean "skip_verify", default: true, null: false
    t.string "state"
    t.integer "style"
    t.integer "type"
    t.datetime "updated_at", null: false
    t.string "user", array: true
    t.index ["config_id"], name: "index_wxwork_contact_ways_on_config_id", unique: true
    t.index ["corporation_id"], name: "index_wxwork_contact_ways_on_corporation_id"
  end

  create_table "wxwork_corporations", force: :cascade do |t|
    t.string "agent_id"
    t.jsonb "agent_info"
    t.integer "agent_max"
    t.jsonb "auth_user_info"
    t.datetime "authorized_at", precision: nil
    t.string "corp_id"
    t.integer "corp_type"
    t.datetime "created_at", null: false
    t.string "full_name"
    t.string "industry"
    t.string "location"
    t.string "name"
    t.string "permanent_code"
    t.string "round_logo_url"
    t.string "scale"
    t.string "square_logo_url"
    t.string "sub_industry"
    t.integer "subject_type"
    t.bigint "suite_id"
    t.datetime "updated_at", null: false
    t.integer "user_max"
    t.datetime "verified_end_time", precision: nil
    t.string "wxqrcode"
    t.index ["corp_id"], name: "index_wxwork_corporations_on_corp_id"
    t.index ["suite_id", "corp_id"], name: "index_wxwork_corporations_on_suite_and_corp", unique: true
    t.index ["suite_id"], name: "index_wxwork_corporations_on_suite_id"
  end

  create_table "wxwork_department_user_maps", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "department_id", null: false
    t.integer "is_leader_in_dept"
    t.integer "order"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["department_id", "user_id"], name: "index_wxwork_department_user_maps_on_dept_and_user", unique: true
    t.index ["department_id"], name: "index_wxwork_department_user_maps_on_department_id"
    t.index ["user_id"], name: "index_wxwork_department_user_maps_on_user_id"
  end

  create_table "wxwork_departments", force: :cascade do |t|
    t.bigint "corporation_id"
    t.datetime "created_at", null: false
    t.integer "dept_id"
    t.string "name"
    t.integer "order"
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["corporation_id", "dept_id"], name: "index_wxwork_departments_on_corp_and_dept", unique: true
    t.index ["corporation_id"], name: "index_wxwork_departments_on_corporation_id"
    t.index ["dept_id"], name: "index_wxwork_departments_on_dept_id"
    t.index ["parent_id"], name: "index_wxwork_departments_on_parent_id"
  end

  create_table "wxwork_event_handlers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "suite_id"
    t.datetime "updated_at", null: false
    t.index ["suite_id"], name: "index_wxwork_event_handlers_on_suite_id", unique: true
  end

  create_table "wxwork_external_contact_follow_user_maps", force: :cascade do |t|
    t.integer "add_way"
    t.datetime "created_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "description"
    t.bigint "external_contact_id"
    t.bigint "follow_user_id"
    t.datetime "followed_at", precision: nil
    t.string "open_user_id"
    t.string "remark"
    t.string "remark_corp_name"
    t.string "state"
    t.datetime "unfollowed_at", precision: nil
    t.datetime "updated_at", null: false
    t.index ["external_contact_id", "follow_user_id"], name: "index_wxwork_external_follow_maps_on_user_ids", unique: true
    t.index ["external_contact_id"], name: "index_wxwork_external_follow_maps_on_external_contact"
    t.index ["follow_user_id"], name: "index_wxwork_external_follow_maps_on_follow_user"
  end

  create_table "wxwork_external_contacts", force: :cascade do |t|
    t.bigint "corporation_id"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "type"
    t.datetime "updated_at", null: false
    t.string "user_id"
    t.index ["corporation_id", "user_id"], name: "index_wxwork_external_contacts_on_corp_and_user", unique: true
    t.index ["corporation_id"], name: "index_wxwork_external_contacts_on_corporation_id"
    t.index ["user_id"], name: "index_wxwork_external_contacts_on_user_id"
  end

  create_table "wxwork_external_users", force: :cascade do |t|
    t.string "corp_id"
    t.datetime "created_at", precision: nil
    t.bigint "external_contact_id"
    t.string "open_id"
    t.string "pending_id"
    t.string "union_id"
    t.index ["corp_id"], name: "index_wxwork_external_users_on_corp_id"
    t.index ["external_contact_id"], name: "index_wxwork_external_users_on_external_contact_id"
    t.index ["open_id"], name: "index_wxwork_external_users_on_open_id"
    t.index ["pending_id"], name: "index_wxwork_external_users_on_pending_id"
  end

  create_table "wxwork_follow_users", force: :cascade do |t|
    t.bigint "corporation_id"
    t.datetime "created_at", null: false
    t.jsonb "custom_settings"
    t.datetime "updated_at", null: false
    t.string "user_id"
    t.index ["corporation_id", "user_id"], name: "index_wxwork_follow_users_on_corp_and_user", unique: true
    t.index ["corporation_id"], name: "index_wxwork_follow_users_on_corporation_id"
    t.index ["user_id"], name: "index_wxwork_follow_users_on_user_id"
  end

  create_table "wxwork_license_accounts", force: :cascade do |t|
    t.integer "account_type"
    t.datetime "activated_at"
    t.string "active_code"
    t.datetime "created_at"
    t.datetime "expires_at"
    t.jsonb "merge_info", default: {}
    t.string "order_id"
    t.jsonb "share_info", default: {}
    t.integer "status"
    t.datetime "updated_at"
    t.string "user_id"
    t.index ["active_code"], name: "index_wxwork_license_accounts_on_active_code", unique: true
    t.index ["order_id"], name: "index_wxwork_license_accounts_on_order_id"
  end

  create_table "wxwork_license_orders", force: :cascade do |t|
    t.integer "base_count"
    t.string "corp_id"
    t.datetime "created_at"
    t.jsonb "duration"
    t.integer "external_contact_count"
    t.string "order_id"
    t.integer "order_type"
    t.datetime "paid_at"
    t.decimal "price", precision: 10, scale: 2
    t.integer "status"
    t.datetime "updated_at"
    t.index ["order_id"], name: "index_wxwork_license_orders_on_order_id", unique: true
  end

  create_table "wxwork_message_handlers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "suite_id"
    t.datetime "updated_at", null: false
    t.index ["suite_id"], name: "index_wxwork_message_handlers_on_suite_id", unique: true
  end

  create_table "wxwork_providers", force: :cascade do |t|
    t.string "corp_id"
    t.datetime "created_at", null: false
    t.string "encoding_aes_key"
    t.string "provider_secret"
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["corp_id"], name: "index_wxwork_providers_on_corp_id", unique: true
  end

  create_table "wxwork_suites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encoding_aes_key"
    t.bigint "provider_id"
    t.string "suite_id"
    t.string "suite_secret"
    t.string "token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_wxwork_suites_on_provider_id"
    t.index ["suite_id"], name: "index_wxwork_suites_on_suite_id", unique: true
    t.index ["uid"], name: "index_wxwork_suites_on_uid", unique: true
  end

  create_table "wxwork_users", force: :cascade do |t|
    t.string "avatar"
    t.bigint "corporation_id"
    t.datetime "created_at", null: false
    t.string "email"
    t.integer "main_department"
    t.string "name"
    t.string "open_userid"
    t.string "qr_code"
    t.integer "status"
    t.string "thumb_avatar"
    t.string "ticket"
    t.datetime "updated_at", null: false
    t.string "user_id"
    t.index ["corporation_id", "user_id"], name: "index_wxwork_users_on_corp_and_user", unique: true
    t.index ["corporation_id"], name: "index_wxwork_users_on_corporation_id"
    t.index ["user_id"], name: "index_wxwork_users_on_user_id"
  end

  add_foreign_key "aato_taggings", "aato_tags", column: "tag_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "tnt_tenants", column: "tenant_id"
  add_foreign_key "contract_envelopes", "contracts"
  add_foreign_key "contract_envelopes", "tenant_docusign_connections"
  add_foreign_key "contract_signers", "contracts"
  add_foreign_key "contract_template_roles", "contract_templates"
  add_foreign_key "contract_templates", "tnt_tenants", column: "tenant_id"
  add_foreign_key "contracts", "tnt_tenants", column: "tenant_id"
  add_foreign_key "contracts", "tnt_users", column: "creator_tenant_user_id"
  add_foreign_key "external_identities", "tnt_tenants", column: "tenant_id"
  add_foreign_key "external_identities", "tnt_users", column: "tenant_user_id"
  add_foreign_key "external_identities", "usr_users", column: "user_id"
  add_foreign_key "feishu_enterprises", "tnt_tenants", column: "tenant_id"
  add_foreign_key "omni_account_postings", "omni_account_accounts", column: "account_id"
  add_foreign_key "omni_account_postings", "omni_account_entries", column: "entry_id"
  add_foreign_key "omni_region_divisions", "omni_region_divisions", column: "parent_id"
  add_foreign_key "org_users", "org_organizations", column: "organization_id"
  add_foreign_key "outbound_events", "tnt_tenants", column: "tenant_id"
  add_foreign_key "owx_message_handlers", "owx_official_accounts", column: "official_account_id"
  add_foreign_key "owx_official_accounts", "owx_third_party_platforms", column: "third_party_platform_id"
  add_foreign_key "owx_open_accounts", "owx_third_party_platforms", column: "third_party_platform_id"
  add_foreign_key "tenant_docusign_connections", "tnt_tenants", column: "tenant_id"
  add_foreign_key "tenant_docusign_connections", "tnt_users", column: "connected_by_tenant_user_id"
  add_foreign_key "tnt_users", "tnt_tenants", column: "tenant_id"
  add_foreign_key "usr_profiles", "usr_users", column: "user_id"
  add_foreign_key "webhook_events", "tnt_tenants", column: "tenant_id"
  add_foreign_key "wxpay_api_client_certificates", "wxpay_vendors", column: "vendor_id"
  add_foreign_key "wxpay_platform_certificates", "wxpay_vendors", column: "vendor_id"
  add_foreign_key "wxpay_public_keys", "wxpay_vendors", column: "vendor_id"
  add_foreign_key "wxwork_corporations", "wxwork_suites", column: "suite_id"
end
