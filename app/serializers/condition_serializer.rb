class ConditionSerializer < ActiveModel::Serializer
  attributes :id, :conditionable_id, :ref_qing_id, :form_id, :op, :value, :option_node_id, :option_set_id
end
