class API::V2::OptionSetsController < API::V2::BaseController
  def update
    @option_set = OptionSet.find(params[:id])
    @option_set.option_nodes.build(
      option_attribs: {
        name_translations: { en: params[:name] },
        latitude: params[:latitude],
        longitude: params[:longitude],
        value: params[:value],
        mission: current_mission
      },
      mission: current_mission,
      ancestry: @option_set.root_node.id
    )

    if @option_set.save
      current_option_node = @option_set.option_nodes.reorder(:created_at).last
      render json: current_option_node.id.to_json, status: :ok
    else
      render json: { error: @option_set.errors }, status: 422
    end
  end
end
