# frozen_string_literal: true

module Insights
  module Concerns
    module Input
      def self.included(base)
        base.class_eval do
          has_many(
            :insights_category_assignments,
            class_name: 'Insights::CategoryAssignment',
            as: :input,  # polymorphic *association*
            dependent: :destroy
          )

          has_many(
            :insights_zsc_tasks_inputs,
            as: :input,
            class_name: 'Insights::ZeroshotClassificationTaskInput',
            dependent: :destroy
          )
        end
      end

      def assignments(view)
        insights_category_assignments.where(view: view)
      end
    end
  end
end
