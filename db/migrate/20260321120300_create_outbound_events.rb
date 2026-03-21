class CreateOutboundEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :outbound_events do |t|
      t.references :tenant, null: true, foreign_key: { to_table: :tnt_tenants }
      t.string :source_type
      t.bigint :source_id
      t.string :event_name, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.text :last_error
      t.datetime :dispatched_at

      t.timestamps
    end

    add_index :outbound_events, %i[status created_at]
    add_index :outbound_events, %i[source_type source_id]
  end
end
