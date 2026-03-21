class CreateWebhookEventsAndAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_events do |t|
      t.references :tenant, null: true, foreign_key: { to_table: :tnt_tenants }
      t.string :provider, null: false, default: "docusign"
      t.string :delivery_id, null: false
      t.string :event_type
      t.string :external_account_id
      t.string :external_event_id
      t.string :status, null: false, default: "received"
      t.integer :processing_attempts, null: false, default: 0
      t.datetime :received_at
      t.datetime :processed_at
      t.text :last_error
      t.jsonb :headers, null: false, default: {}
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :webhook_events, %i[provider delivery_id], unique: true
    add_index :webhook_events, %i[status created_at]
    add_index :webhook_events, %i[provider external_account_id]

    create_table :audit_logs do |t|
      t.references :tenant, null: true, foreign_key: { to_table: :tnt_tenants }
      t.string :actor_type
      t.bigint :actor_id
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.string :request_id
      t.string :ip
      t.string :user_agent
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, %i[action created_at]
    add_index :audit_logs, %i[target_type target_id]
    add_index :audit_logs, %i[actor_type actor_id]
  end
end
