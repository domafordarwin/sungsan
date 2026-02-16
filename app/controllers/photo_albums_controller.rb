class PhotoAlbumsController < ApplicationController
  before_action :set_album, only: %i[show edit update destroy]

  def index
    authorize PhotoAlbum
    @albums = policy_scope(PhotoAlbum).recent.includes(:author, :photos).page(params[:page]).per(12)
  end

  def show
    authorize @album
    @photos = @album.photos.ordered.includes(image_attachment: :blob)
  end

  def new
    @album = PhotoAlbum.new
    authorize @album
  end

  def create
    @album = PhotoAlbum.new(album_params)
    @album.author = Current.user
    @album.parish_id = Current.parish_id
    authorize @album

    if @album.save
      redirect_to photo_album_path(@album), notice: "앨범이 생성되었습니다. 사진을 추가해주세요!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @album
  end

  def update
    authorize @album
    if @album.update(album_params)
      redirect_to photo_album_path(@album), notice: "앨범 정보가 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @album
    @album.destroy!
    redirect_to photo_albums_path, notice: "앨범이 삭제되었습니다."
  end

  private

  def set_album
    @album = PhotoAlbum.find(params[:id])
  end

  def album_params
    params.require(:photo_album).permit(:title, :description, :event_date)
  end
end
