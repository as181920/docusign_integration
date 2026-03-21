class CreateActsAsTaggableOnTables < ActiveRecord::Migration[8.1]
  def change
    create_table :aato_tags do |t|
      t.string :name
      t.integer :taggings_count, default: 0

      t.timestamps
    end

    create_table :aato_taggings do |t|
      t.references :tag, foreign_key: { to_table: :aato_tags }
      t.references :taggable, polymorphic: true
      t.references :tagger, polymorphic: true
      t.string :context, limit: 128
      t.datetime :created_at
    end

    add_index :aato_tags, :name, unique: true
    add_index :aato_taggings, :context
    add_index :aato_taggings, %i[tag_id taggable_id taggable_type context tagger_id tagger_type], unique: true, name: "taggings_idx"
    add_index :aato_taggings, %i[taggable_id taggable_type context], name: "taggings_taggable_context_idx"
    add_index :aato_taggings, %i[taggable_id taggable_type tagger_id context], name: "taggings_idy"
    add_index :aato_taggings, %i[tagger_id tagger_type]
  end
end
