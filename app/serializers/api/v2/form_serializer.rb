class API::V2::FormSerializer < ActiveModel::Serializer
  attributes :id, :name, :questions, :updatedAt

  def questions
    formatted_questionings = {}
    object.arrange_descendants.each do |questioning, data|
      formatted_questionings[questioning.rank] = {
        type: questioning.is_a?(QingGroup) ? 'Group' : 'Question',
        name: questioning.is_a?(QingGroup) ? questioning.group_name : nil,
        data: questioning.is_a?(QingGroup) ? serialize_group(data) : serialize_question(questioning)
      }
    end
    formatted_questionings
  end

  def updatedAt
    object.created_at.to_i * 1000
  end

  private

  def serialize_question(question)
    {
      id: question.qid,
      title: question.name,
      hint: question.hint,
      type: question.qtype_name,
      options: question.qtype_name.in?(['select_one', 'select_multiple']) ? question.preordered_option_nodes.map{ |on| { label: on.option.name, value:  on.id} } : nil
    }
  end

  def serialize_group(group)
    group.map do |question, _|
      serialize_question(question)
    end
  end
end
