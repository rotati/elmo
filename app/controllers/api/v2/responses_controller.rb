class API::V2::ResponsesController < API::V2::BaseController
  def create
    @response = Response.new(response_params)
    @response.source = "web"
    @response.modifier = "web"
    @response.mission = @api_user.last_mission

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
      reviewer_only = if @response.present?
        [:reviewed, :reviewer_notes, :reviewer_id]
      else
        []
      end

      params.require(:response).permit(:form_id, :user_id, :incomplete, *reviewer_only).tap do |permitted|
        # In some rare cases, create or update can occur without answers_attributes. Not sure how.
        # Also need to respect the modify_answers permission here.
        if params[:response][:answers_attributes] &&
          (action_name != "update" || can?(:modify_answers, @response))
          permit_answer_attributes(permitted)
        end
      end
    end
  end

  def permit_answer_attributes(permitted)
    permitted[:answers_attributes] = {}

    # The answers_attributes hash might look like {'2746' => { ... }, '2731' => { ... }, ... }
    # The keys are irrelevant so we permit all of them, but we only want to permit certain attribs
    # on the answers.
    permitted_answer_attribs = %w(id value option_id option_node_id questioning_id relevant rank
      time_value(1i) time_value(2i) time_value(3i) time_value(4i) time_value(5i) time_value(6i)
      datetime_value
      datetime_value(1i) datetime_value(2i) datetime_value(3i)
      datetime_value(4i) datetime_value(5i) datetime_value(6i)
      date_value(1i) date_value(2i) date_value(3i) inst_num media_object_id _destroy
      date_value)

    params[:response][:answers_attributes].each do |idx, attribs|
      permitted[:answers_attributes][idx] = attribs.permit(*permitted_answer_attribs)
      # Handle choices, which are nested under answers.
      if attribs[:choices_attributes]
        permitted[:answers_attributes][idx][:choices_attributes] = {}
        attribs[:choices_attributes].each do |idx2, attribs2|
          permitted[:answers_attributes][idx][:choices_attributes][idx2] = attribs2.permit(
            :id, :option_id, :option_node_id, :checked)
        end
      end
    end
  end
end
