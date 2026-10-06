class PlaylistsController < ApplicationController
  before_action :set_playlist, only: %i[edit update destroy]

  def index
    @playlists = current_user.playlists.includes(:entries).order(:name)
  end

  def new
    @playlist = current_user.playlists.build
  end

  def create
    @playlist = current_user.playlists.build(playlist_params)

    if @playlist.save
      redirect_to playlists_path, notice: "Playlist créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @playlist.update(playlist_params)
      redirect_to playlists_path, notice: "Playlist renommée."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @playlist.destroy
    redirect_to playlists_path, notice: "Playlist supprimée.", status: :see_other
  end

  private

  def set_playlist
    @playlist = current_user.playlists.find(params[:id])
  end

  def playlist_params
    params.expect(playlist: %i[name])
  end
end
