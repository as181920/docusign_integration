class CreateFeishuEnterprisesAndExternalIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :feishu_enterprises do |t|
      t.references :tenant, null: false, foreign_key: { to_table: :tnt_tenants }, index: { unique: true }
      t.string :tenant_key, null: false
      t.string :app_id
      t.string :name
      t.string :status, null: false, default: "active"
      t.jsonb :raw_payload, null: false, default: {}

      t.timestamps
    end

    add_index :feishu_enterprises, :tenant_key, unique: true

    create_table :external_identities do |t|
      t.references :user, null: false, foreign_key: { to_table: :usr_users }
      t.references :tenant, null: false, foreign_key: { to_table: :tnt_tenants }
      t.references :tenant_user, null: true, foreign_key: { to_table: :tnt_users }
      t.string :provider, null: false
      t.string :provider_uid, null: false
      t.string :union_id
      t.string :open_id
      t.string :name
      t.string :avatar_url
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :external_identities, %i[tenant_id provider provider_uid], unique: true
    add_index :external_identities, %i[tenant_id provider union_id], unique: true, where: "union_id IS NOT NULL"
    add_index :external_identities, %i[tenant_id provider open_id], unique: true, where: "open_id IS NOT NULL"
  end
end
