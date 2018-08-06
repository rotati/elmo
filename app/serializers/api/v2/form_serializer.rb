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
      id: question.id,
      title: question.name,
      hint: question.hint,
      type: question.qtype_name,
      options: question.qtype_name.in?(['select_one', 'select_multiple']) ? options(question) : nil,
      choose_once: question.choose_once
    }
  end

  def serialize_group(group)
    group.map do |question, _|
      serialize_question(question)
    end
  end

  def options(question)
    {
      multilevel: question.option_set.multilevel?,
      geographic: question.option_set.geographic,
      allow_coordinates: question.option_set.allow_coordinates,
      data: question.preordered_option_nodes.map do |on|
        {
          label: on.option.name,
          value:  on.id,
          latitude: on.option.latitude.to_f,
          longitude: on.option.longitude.to_f
        }
      end
    }
  end
end
