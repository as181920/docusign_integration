class CreateContractTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :contract_templates do |t|
      t.references :tenant, null: false, foreign_key: { to_table: :tnt_tenants }
      t.string :name, null: false
      t.integer :version, null: false, default: 1
      t.string :status, null: false, default: "active"
      t.string :docusign_template_id
      t.string :description
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :contract_templates, %i[tenant_id name version], unique: true
    add_index :contract_templates, %i[tenant_id name status]
  end
end
