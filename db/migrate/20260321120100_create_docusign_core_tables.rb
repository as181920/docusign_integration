class CreateDocusignCoreTables < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_docusign_connections do |t|
      t.references :tenant, null: false, foreign_key: { to_table: :tnt_tenants }, index: { unique: true }
      t.bigint :connected_by_tenant_user_id
      t.string :docusign_account_id, null: false
      t.string :docusign_base_uri
      t.string :oauth_scope, null: false, default: "signature"
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at
      t.datetime :connected_at
      t.string :status, null: false, default: "active"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :tenant_docusign_connections, :docusign_account_id, unique: true
    add_foreign_key :tenant_docusign_connections, :tnt_users, column: :connected_by_tenant_user_id

    create_table :contracts do |t|
      t.references :tenant, null: false, foreign_key: { to_table: :tnt_tenants }
      t.bigint :creator_tenant_user_id
      t.string :title, null: false
      t.string :contract_no, null: false
      t.string :status, null: false, default: "draft"
      t.string :source, null: false, default: "manual"
      t.string :language, null: false, default: "en"
      t.string :currency, null: false, default: "USD"
      t.string :docusign_template_id
      t.datetime :sent_at
      t.datetime :completed_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :contracts, %i[tenant_id contract_no], unique: true
    add_foreign_key :contracts, :tnt_users, column: :creator_tenant_user_id

    create_table :contract_signers do |t|
      t.references :contract, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :role_name, null: false
      t.integer :routing_order, null: false, default: 1
      t.string :signing_type, null: false, default: "signer"
      t.string :status, null: false, default: "pending"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :contract_signers, %i[contract_id email role_name], unique: true

    create_table :contract_envelopes do |t|
      t.references :contract, null: false, foreign_key: true, index: { unique: true }
      t.references :tenant_docusign_connection, null: false, foreign_key: true
      t.string :envelope_id, null: false
      t.string :status, null: false, default: "created"
      t.datetime :last_synced_at
      t.datetime :sent_at
      t.datetime :completed_at
      t.datetime :declined_at
      t.datetime :voided_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :contract_envelopes, :envelope_id, unique: true
  end
end
