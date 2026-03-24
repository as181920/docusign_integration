class AddPublishFieldsAndRolesForContractTemplates < ActiveRecord::Migration[8.1]
  def change
    change_table :contract_templates, bulk: true do |t|
      t.string :email_subject
      t.text :email_message
      t.string :publish_state, null: false, default: "draft"
      t.datetime :published_at
    end

    add_index :contract_templates, %i[tenant_id publish_state]

    create_table :contract_template_roles do |t|
      t.references :contract_template, null: false, foreign_key: true
      t.string :role_name, null: false
      t.string :signer_name
      t.string :signer_email
      t.integer :routing_order, null: false, default: 1
      t.string :signing_type, null: false, default: "signer"
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :contract_template_roles,
      %i[contract_template_id role_name signing_type],
      unique: true,
      name: "idx_contract_template_roles_on_template_role_and_type"

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE contract_templates
          SET publish_state = CASE
            WHEN docusign_template_id IS NOT NULL AND docusign_template_id <> '' THEN 'published'
            ELSE 'draft'
          END,
          published_at = CASE
            WHEN docusign_template_id IS NOT NULL AND docusign_template_id <> '' THEN updated_at
            ELSE NULL
          END
        SQL
      end
    end
  end
end
