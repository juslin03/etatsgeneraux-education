module SmartGroups::Rules
  class ParticipatedInIdeaStatus
    include ActiveModel::Validations
    include DescribableRule

    PREDICATE_VALUES = %w(in not_in posted_in not_posted_in commented_in not_commented_in voted_idea_in not_voted_idea_in voted_comment_in not_voted_comment_in)
    VALUELESS_PREDICATES = []

    attr_accessor :predicate, :value

    validates :predicate, presence: true
    validates :predicate, inclusion: { in: PREDICATE_VALUES }
    validates :value, presence: true, inclusion: { in: -> (record) { IdeaStatus.ids } }

    def self.to_json_schema
      [
        {
          "type": "object",
          "required" => ["ruleType", "predicate", "value"],
          "additionalProperties" => false,
          "properties" => {
            "ruleType" => {
              "type" => "string",
              "enum" => [rule_type],
            },
            "predicate" => {
              "type": "string",
              "enum": PREDICATE_VALUES - VALUELESS_PREDICATES,
            },
            "value" => {
              "description" => "The id of an idea status",
              "type" => "string"
            }
          },
        },
      ]
    end

    def self.rule_type
      'participated_in_idea_status'
    end

    def self.from_json json
      self.new(json['predicate'], json['value'])
    end

    def initialize predicate, value
      self.predicate = predicate
      self.value = value
    end

    def filter users_scope
      participants_service = ParticipantsService.new

      case predicate
      when 'in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)])
        users_scope.where(id: participants)
      when 'not_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)])
        users_scope.where.not(id: participants)
      when 'posted_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:posting])
        users_scope.where(id: participants)
      when 'not_posted_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:posting])
        users_scope.where.not(id: participants)
      when 'commented_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:commenting])
        users_scope.where(id: participants)
      when 'not_commented_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:commenting])
        users_scope.where.not(id: participants)
      when 'voted_idea_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:idea_voting])
        users_scope.where(id: participants)
      when 'not_voted_idea_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:idea_voting])
        users_scope.where.not(id: participants)
      when 'voted_comment_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:comment_voting])
        users_scope.where(id: participants)
      when 'not_voted_comment_in'
        participants = participants_service.idea_statuses_participants([IdeaStatus.find(value)], actions: [:comment_voting])
        users_scope.where.not(id: participants)
      else
        raise "Unsupported predicate #{predicate}"
      end
    end

    def description_value locale
      IdeaStatus.find(value).title_multiloc[locale]
    end

  end
end
