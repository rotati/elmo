class API::V2::FormsController < API::V2::BaseController
  def index
    forms = @api_user.last_mission.forms
    render json: forms, each_serializer: API::V2::FormSerializer
  end
end
