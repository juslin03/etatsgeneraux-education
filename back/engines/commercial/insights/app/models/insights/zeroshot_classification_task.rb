# frozen_string_literal: true

module Insights
  class ZeroshotClassificationTask < ::ApplicationRecord
    has_and_belongs_to_many :categories, join_table: 'insights_zeroshot_classification_tasks_categories', foreign_key: :task_id
    has_many :tasks_inputs, 
             class_name: 'Insights::ZeroshotClassificationTaskInput', 
             foreign_key: :task_id, dependent: :destroy

    validates :task_id, presence: true, uniqueness: true

    def inputs
      tasks_inputs.map(&:input)
    end
  end
end
