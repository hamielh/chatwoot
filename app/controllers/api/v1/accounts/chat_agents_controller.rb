class Api::V1::Accounts::ChatAgentsController < Api::V1::Accounts::BaseController
  before_action :check_chat_agents_feature_enabled
  before_action :fetch_chat_agents, except: [:create]
  before_action :fetch_chat_agent, only: [:show, :update, :destroy]

  def index; end

  def show; end

  def create
    @chat_agent = Current.account.chat_agents.create!(
      permitted_payload.merge(user_id: Current.user.id)
    )
  end

  def update
    @chat_agent.update!(permitted_payload)
  end

  def destroy
    @chat_agent.destroy!
    head :no_content
  end

  private

  def fetch_chat_agents
    @chat_agents = Current.account.chat_agents.enabled.ordered.for_role(Current.user.role)
  end

  def fetch_chat_agent
    @chat_agent = @chat_agents.find(permitted_params[:id])
  end

  def permitted_payload
    params.require(:chat_agent).permit(
      :title,
      :webhook_url,
      :description,
      :position,
      :icon,
      :enabled,
      allowed_roles: [],
      webhook_params: {}
    )
  end

  def permitted_params
    params.permit(:id)
  end

  def check_chat_agents_feature_enabled
    return if Current.account.feature_enabled?('chat_agents')

    render json: { error: 'Chat Agents feature is not enabled for this account' }, status: :forbidden
  end
end
