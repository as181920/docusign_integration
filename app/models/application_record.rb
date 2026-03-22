class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class << self
    def ransackable_attributes(_auth_object = nil)
      column_names + _ransackers.keys
    end

    def ransackable_associations(_auth_object = nil)
      reflect_on_all_associations.map { |association| association.name.to_s }
    end
  end
end
