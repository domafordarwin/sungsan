class PhotosController < ApplicationController
  before_action :set_album

  def create
    authorize @album, :update?, policy_class: PhotoAlbumPolicy

    photos_params = params[:photos] || []
    count = 0

    photos_params.each do |image|
      photo = @album.photos.build(
        uploader: Current.user,
        image: image,
        caption: "",
        position: @album.photos.count
      )
      count += 1 if photo.save
    end

    if count > 0
      redirect_to photo_album_path(@album), notice: "#{count}장의 사진이 업로드되었습니다."
    else
      redirect_to photo_album_path(@album), alert: "사진 업로드에 실패했습니다. 이미지 파일을 선택해주세요."
    end
  end

  def destroy
    @photo = @album.photos.find(params[:id])
    authorize @album, :update?, policy_class: PhotoAlbumPolicy

    @photo.destroy!
    redirect_to photo_album_path(@album), notice: "사진이 삭제되었습니다."
  end

  private

  def set_album
    @album = PhotoAlbum.find(params[:photo_album_id])
  end
end
