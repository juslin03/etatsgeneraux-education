require "rails_helper"

describe SmartGroups::RulesService do
  let(:service) { SmartGroups::RulesService.new }
  let(:metaschema) { JSON::Validator.validator_for_name("draft4").metaschema }

  let(:cf1) { create(:custom_field) }
  let(:cf2) { create(:custom_field) }
  let(:options) { create_list(:custom_field_option, 3) }
  let(:cf3) { create(:custom_field_select) }
  let(:options) { create_list(:custom_field_option, 3, custom_field: cf3 )}
  let!(:users) {
    users = build_list(:admin, 4)
    users[0].custom_field_values[cf1.key] = 'one'
    users[0].custom_field_values[cf2.key] = 'a'
    users[0].custom_field_values[cf3.key] = options[0].key

    users[1].custom_field_values[cf1.key] = 'three'
    users[1].custom_field_values[cf2.key] = 'a'
    users[1].custom_field_values[cf3.key] = options[0].key

    users[2].custom_field_values[cf1.key] = 'three'
    users[2].custom_field_values[cf2.key] = 'a'
    users[2].custom_field_values[cf3.key] = options[1].key

    users[3].custom_field_values[cf1.key] = 'four'
    users[3].custom_field_values[cf2.key] = 'a'
    users[3].custom_field_values[cf3.key] = options[2].key

    users.each(&:save)
  }

  let(:rules) {[
    { 'ruleType' => 'custom_field_text', 'customFieldId' => cf1.id, 'predicate' => 'is', 'value' => 'three' },
    { 'ruleType' => 'custom_field_text', 'customFieldId' => cf2.id, 'predicate' => 'is', 'value' => 'a' },
    { 'ruleType' => 'custom_field_select', 'customFieldId' => cf3.id, 'predicate' => 'has_value', 'value' => options[1].id },
    { 'ruleType' => 'role', 'predicate' => 'is_admin' }
  ]}

  describe "generate_rules_json_schema" do

    let!(:cf1) { create(:custom_field) }

    it "generates a valid json schema" do
      schema = service.generate_rules_json_schema
      expect(JSON::Validator.validate!(metaschema, schema)).to be true
    end

    it "successfully validates various valid rules" do
      schema = service.generate_rules_json_schema
      expect(JSON::Validator.validate!(schema, rules)).to be true
    end

    it "successfully validates valid custom field date rule" do
      schema = service.generate_rules_json_schema
      invalid_rule = {
        'ruleType' => 'custom_field_date',
        'customFieldId' => create(:custom_field_date).id,
        'predicate' => 'is_before',
        'value' => '2018-05-04'
      }
      expect(JSON::Validator.validate(schema, [invalid_rule])).to be true
    end

    it "rejects invalid custom field date rule" do
      schema = service.generate_rules_json_schema
      invalid_rule = {
        'ruleType' => 'custom_field_date',
        'customFieldId' => create(:custom_field_date).id,
        'predicate' => 'is_before',
        'value' => 'garbage'
      }
      expect(JSON::Validator.validate(schema, [invalid_rule])).to be false
    end

  end

  describe "filter" do

    it "filters users with a combination of diverse rules" do
      result = service.filter ::User, rules
      expect(result.count).to eq 1
    end
  end


  describe "groups_for_user" do
    let!(:group1) { create(:smart_group, rules: [{ruleType: 'email', predicate: 'is', value: 'me@test.com'}]) }
    let!(:group2) { create(:smart_group, rules: [{ruleType: 'email', predicate: 'is', value: 'you@test.org'}]) }
    let!(:user) { create(:user, email: 'me@test.com') }

    it "returns only the rules groups the user is part of" do
      groups = service.groups_for_user(user)
      expect(groups.map(&:id)).to eq [group1.id]
    end

    it "uses a maximun of 2 queries" do
      query_count = count_queries do
        groups = service.groups_for_user(user)
      end
      expect(query_count).to be <= 2
    end

  end

  describe "filter_by_rule_type" do
    let!(:group1) { create(:smart_group, rules: [
      {ruleType: 'lives_in', predicate: 'has_value', value: create(:area).id}
    ])}
    let!(:group2) { create(:smart_group, rules: [
      {ruleType: 'email', predicate: 'is', value: 'abcd'}
    ])}
    let!(:group3) { create(:smart_group, rules: [
      {ruleType: 'lives_in', predicate: 'has_value', value: create(:area).id},
      {ruleType: 'email', predicate: 'is', value: 'abcd'},
    ])}

    it "filters out smart groups that have rules of the given type" do
      scope = Group.all
      expect(service.filter_by_rule_type(scope, 'lives_in')).to match_array [group1, group3]
    end

    it "returns a scope that can be queried further" do
      scope = service.filter_by_rule_type(Group.all, 'lives_in')
      expect(scope.where(id: group1.id).ids).to eq [group1.id]
    end
  end

  describe "filter_by_rule_value" do
    let(:area1) { create(:area) }
    let(:area2) { create(:area) }
    let!(:group1) { create(:smart_group, rules: [
      {ruleType: 'lives_in', predicate: 'has_value', value: area1.id}
    ])}
    let!(:group2) { create(:smart_group, rules: [
      {ruleType: 'email', predicate: 'is', value: 'abcd'}
    ])}
    let!(:group3) { create(:smart_group, rules: [
      {ruleType: 'lives_in', predicate: 'has_value', value: area2.id},
      {ruleType: 'registration_completed_at', predicate: 'is_empty'},
    ])}

    it "filters out smart groups that have the given value" do
      scope = Group.all
      expect(service.filter_by_rule_value(scope, area1.id)).to match_array [group1]
    end

    it "returns a scope that can be queried further" do
      scope = service.filter_by_rule_value(Group.all, 'fictionalidvalue')
      expect(scope.ids).to be_empty
    end
  end

  private

  def count_queries &block
    count = 0

    counter_f = ->(name, started, finished, unique_id, payload) {
      unless payload[:name].in? %w[ CACHE SCHEMA ]
        count += 1
      end
    }

    ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)

    count
  end

end
