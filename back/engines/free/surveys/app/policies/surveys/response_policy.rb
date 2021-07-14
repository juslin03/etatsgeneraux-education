module Surveys
  class ResponsePolicy < ApplicationPolicy
    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user  = user
        @scope = scope
      end

      def resolve
        moderatable_projects = ProjectPolicy::Scope.new(user, Project).moderatable
        moderatable_phases = Phase.where(project: moderatable_projects)
        scope
          .where(participation_context: moderatable_projects + moderatable_phases)
      end
    end

    def index_xlsx?
      user&.active? && user.admin?
    end


  end
end