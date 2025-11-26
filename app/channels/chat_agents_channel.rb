class ChatAgentsChannel < ApplicationCable::Channel
  def subscribed
    ensure_stream
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def ensure_stream
    stream_from "accounts:#{params[:account_id]}:chat_agents"
  end
end
