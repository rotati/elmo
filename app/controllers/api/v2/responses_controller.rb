class API::V2::ResponsesController < API::V2::BaseController
  def create
    @response = Response.new(response_params)
    @response.source = "web"
    @response.modifier = "web"
    @response.mission = current_mission

    begin
      @response.save!
      render json: { message: ["success"] }, status: :ok
    rescue ActiveRecord::RecordInvalid
      render json: { error: ["error"] }, status: 422
    end
  end

  private

  def response_params
    if params[:response]
      to_permit = [:form_id, :user_id, :incomplete]

      if (ans_attribs = params[:response][:answers_attributes]) &&
          (action_name != "update" || can?(:modify_answers, @response))

        to_permit << {
          answers_attributes: ans_attribs.keys.map { |k| [k, permitted_answer_attributes] }.to_h
        }
      end

      params.require(:response).permit(to_permit)
    end
  end

  def permitted_answer_attributes
    @permitted_answer_attributes ||= %w(
      id value option_id option_node_id questioning_id relevant rank
      time_value(1i) time_value(2i) time_value(3i) time_value(4i) time_value(5i) time_value(6i)
      datetime_value
      datetime_value(1i) datetime_value(2i) datetime_value(3i)
      datetime_value(4i) datetime_value(5i) datetime_value(6i)
      date_value(1i) date_value(2i) date_value(3i) inst_num media_object_id _destroy
      date_value
    ) << {choices_attributes: %i[id option_id option_node_id checked]}
  end
end
