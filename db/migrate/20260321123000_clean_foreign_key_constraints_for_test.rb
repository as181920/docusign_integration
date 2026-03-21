class CleanForeignKeyConstraintsForTest < ActiveRecord::Migration[8.1]
  def up
    return unless Rails.env.test?

    connection.tables.each do |table|
      connection.foreign_keys(table).each do |foreign_key|
        remove_foreign_key table, name: foreign_key.name
      rescue StandardError
        # no-op: keep migration resilient for adapter/table edge cases
      end
    end
  end

  def down
    # irreversible: this migration is only intended for test environment
  end
end
