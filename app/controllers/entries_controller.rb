class EntriesController < ApplicationController
  before_action :set_entry, only: %i[edit update destroy]

  def index
    @entries = policy_scope(Entry).includes(:playlist).order(created_at: :desc)
  end

  def new
    @entry = current_user.entries.build
    authorize @entry
  end

  def create
    @entry = current_user.entries.build(entry_params)
    authorize @entry

    if @entry.save
      redirect_to entries_path, notice: "Titre ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @entry.update(entry_params)
      redirect_to entries_path, notice: "Titre mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    redirect_to entries_path, notice: "Titre supprimé.", status: :see_other
  end

  private

  def set_entry
    @entry = Entry.find(params[:id])
    authorize @entry
  end

  def entry_params
    params.expect(entry: %i[title status rating platform playlist_id])
  end
end
