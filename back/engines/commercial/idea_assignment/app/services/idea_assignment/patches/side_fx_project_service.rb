module IdeaAssignment
  module Patches
    module SideFxProjectService
      def before_create(project, current_user)
        super
        set_default_assignee(project, current_user)
      end

      private

      def set_default_assignee(project, current_user)
        project.default_assignee ||= if current_user&.super_admin?
                                        ::User.oldest_admin
                                     else
                                       current_user
                                     end
      end
    end
  end
end
