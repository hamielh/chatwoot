class Api::V1::Accounts::Conversations::ScheduledMessagesController < Api::V1::Accounts::Conversations::BaseController
  def index
    @scheduled_messages = @conversation.scheduled_messages.pending.order(scheduled_at: :asc)
  end

  def create
    @scheduled_message = @conversation.scheduled_messages.build(
      account_id: Current.account.id,
      content: params[:content],
      scheduled_at: params[:scheduled_at],
      private: params[:private] || false,
      created_by: Current.user
    )
    @scheduled_message.files.attach(params[:attachments]) if params[:attachments].present?
    @scheduled_message.save!
  end

  def destroy
    @scheduled_message = @conversation.scheduled_messages.pending.find(params[:id])
    @scheduled_message.cancelled!
    head :ok
  end
end
