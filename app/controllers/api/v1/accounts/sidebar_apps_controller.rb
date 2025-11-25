class Api::V1::Accounts::SidebarAppsController < Api::V1::Accounts::BaseController
  before_action :fetch_sidebar_apps, except: [:create]
  before_action :fetch_sidebar_app, only: [:show, :update, :destroy]

  def index; end

  def show; end

  def create
    @sidebar_app = Current.account.sidebar_apps.create!(
      permitted_payload.merge(user_id: Current.user.id)
    )
  end

  def update
    @sidebar_app.update!(permitted_payload)
  end

  def destroy
    @sidebar_app.destroy!
    head :no_content
  end

  private

  def fetch_sidebar_apps
    @sidebar_apps = Current.account.sidebar_apps.ordered
  end

  def fetch_sidebar_app
    @sidebar_app = @sidebar_apps.find(permitted_params[:id])
  end

  def permitted_payload
    params.require(:sidebar_app).permit(
      :title,
      :url,
      :display_location,
      :position,
      :icon,
      allowed_roles: []
    )
  end

  def permitted_params
    params.permit(:id)
  end
end
