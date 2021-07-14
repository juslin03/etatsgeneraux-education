require "rails_helper"

describe SmartGroups::Rules::ParticipatedInTopic do

  let(:valid_json_rule) {{
    'ruleType' => 'participated_in_topic',
    'predicate' => 'in',
    'value' => create(:topic).id
  }}
  let(:valid_rule) { SmartGroups::Rules::ParticipatedInTopic.from_json(valid_json_rule) }

  describe "from_json" do

    it "successfully parses a valid json" do
      expect(valid_rule.predicate).to eq valid_json_rule['predicate']
      expect(valid_rule.value).to eq valid_json_rule['value']
    end

  end

  describe "validations" do
    it "successfully validate the valid rule" do
      expect(valid_rule).to be_valid
      expect(build(:smart_group, rules: [valid_json_rule])).to be_valid
    end
  end

  describe "filter" do

    before do
      @topic1 = create(:topic)
      @topic2 = create(:topic)
      @project = create(:project, topics: [@topic1, @topic2])
      @user1 = create(:user)
      @user2 = create(:user)
      @user3 = create(:user)
      @user4 = create(:user)
      @idea1 = create(:idea, topics: [@topic1], author: @user1, project: @project)
      @comment = create(:comment, post: @idea1, author: @user3)
      @vote = create(:vote, votable: @comment, user: @user2)
      @idea2 = create(:idea, topics: [@topic2], author: @user3, project: @project)
    end

    it "correctly filters on 'in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user1, @user2, @user3]
    end

    it "correctly filters on 'not_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('not_in', @topic2.id)
      expect(rule.filter(User)).to match_array [@user1, @user2, @user4]
    end

    it "correctly filters on 'posted_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('posted_in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user1]
    end

    it "correctly filters on 'not_posted_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('not_posted_in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user2, @user3, @user4]
    end

    it "correctly filters on 'commented_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('commented_in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user3]
    end

    it "correctly filters on 'not_commented_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('not_commented_in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user1, @user2, @user4]
    end

    it "correctly filters on 'voted_idea_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('voted_idea_in', @topic1.id)
      expect(rule.filter(User)).to match_array []
    end

    it "correctly filters on 'not_voted_idea_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('not_voted_idea_in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user1, @user2, @user3, @user4]
    end

    it "correctly filters on 'voted_comment_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('voted_comment_in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user2]
    end

    it "correctly filters on 'not_voted_comment_in' predicate" do
      rule = SmartGroups::Rules::ParticipatedInTopic.new('not_voted_comment_in', @topic1.id)
      expect(rule.filter(User)).to match_array [@user1, @user3, @user4]
    end

  end

  describe "description_multiloc" do
    let(:topic) { create(:topic, title_multiloc: {
      'en'    => 'beer',
      'fr-FR' => 'bière',
      'nl-NL' => 'bier'
    }) }

    let(:participated_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'in',
      'value'         => topic.id
    })}
    let(:participated_not_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'not_in',
      'value'         => topic.id
    })}
    let(:participated_posted_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'posted_in',
      'value'         => topic.id
    })}
    let(:participated_not_posted_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'not_posted_in',
      'value'         => topic.id
    })}
    let(:participated_commented_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'commented_in',
      'value'         => topic.id
    })}
    let(:participated_not_commented_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'not_commented_in',
      'value'         => topic.id
    })}
    let(:participated_voted_idea_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'voted_idea_in',
      'value'         => topic.id
    })}
    let(:participated_not_voted_idea_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'not_voted_idea_in',
      'value'         => topic.id
    })}
    let(:participated_voted_comment_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'voted_comment_in',
      'value'         => topic.id
    })}
    let(:participated_not_voted_comment_in_topic_in_rule) {SmartGroups::Rules::ParticipatedInTopic.from_json({
      'ruleType'      => 'participated_in_topic',
      'predicate'     => 'not_voted_comment_in',
      'value'         => topic.id
    })}

    it "successfully translates different combinations of rules" do
      # Stubbing the translations so the specs don't depend on those.
      I18n.load_path += Dir[Rails.root.join('spec', 'fixtures', 'locales', '*.yml')]

      expect(participated_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Participation in an idea with topic beer',
        'fr-FR' => 'Participation dans une idée avec thème bière',
        'nl-NL' => 'Participatie in een idee met thema bier'
      })
      expect(participated_not_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'No participation in an idea with topic beer',
        'fr-FR' => 'Pas de participation dans une idée avec thème bière',
        'nl-NL' => 'Geen participatie in een idee met thema bier'
      })
      expect(participated_posted_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Posted an idea with topic beer',
        'fr-FR' => 'Posté une idée avec thème bière',
        'nl-NL' => 'Plaatste een idee met thema bier'
      })
      expect(participated_not_posted_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Did not post an idea with topic beer',
        'fr-FR' => 'N\'as pas posté une idée avec thème bière',
        'nl-NL' => 'Plaatste geen idee met thema bier'
      })
      expect(participated_commented_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Commented on an idea with topic beer',
        'fr-FR' => 'Commenté sur une idée avec thème bière',
        'nl-NL' => 'Reageerde op een idee met thema bier'
      })
      expect(participated_not_commented_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Did not comment on an idea with topic beer',
        'fr-FR' => 'N\'as pas commenté sur une idée avec thème bière',
        'nl-NL' => 'Reageerde niet op een idee met thema bier'
      })
      expect(participated_voted_idea_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Voted on an idea with topic beer',
        'fr-FR' => 'Voté pour une idée avec thème bière',
        'nl-NL' => 'Stemde op een idee met thema bier'
      })
      expect(participated_not_voted_idea_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Did not vote on an idea with topic beer',
        'fr-FR' => 'N\'as pas voté pour une idée avec thème bière',
        'nl-NL' => 'Stemde niet op een idee met thema bier'
      })
      expect(participated_voted_comment_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Voted on a comment on an idea with topic beer',
        'fr-FR' => 'Voté pour un commentaire sur une idée avec thème bière',
        'nl-NL' => 'Stemde op een reactie op een idee met thema bier'
      })
      expect(participated_not_voted_comment_in_topic_in_rule.description_multiloc).to eq ({
        'en'    => 'Did not vote on a comment on an idea with topic beer',
        'fr-FR' => 'N\'as pas voté pour un commentaire sur une idée avec thème bière',
        'nl-NL' => 'Stemde niet op een reactie op een idee met thema bier'
      })
    end
  end

end
