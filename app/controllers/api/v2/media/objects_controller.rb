class API::V2::Media::ObjectsController < API::V2::BaseController
  def create
    media = media_class(params[:type]).new(item: params[:upload])
    if media.save
      render json: { id: media.id }, status: 201
    else
      msg = I18n.t("activerecord.errors.models.media/object.invalid_format")
      render json: { errors: [msg] }, status: 422
    end
  end

  def delete
    media_object = Media::Object.find(params[:id])
    media_object.destroy
    render body: nil, status: 204
  end

  private

  def media_object_params
    params.require(:media_object).permit(:answer_id, :annotation)
  end

  def media_class(type)
    case type
    when "audios"
      return Media::Audio
    when "videos"
      return Media::Video
    when "images"
      return Media::Image
    else
      raise "A valid media type must be specified"
    end
  end
end
