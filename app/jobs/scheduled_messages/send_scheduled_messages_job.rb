class ScheduledMessages::SendScheduledMessagesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    ScheduledMessage.sendable.find_each(batch_size: 100) do |scheduled_message|
      ScheduledMessages::SendMessageJob.perform_later(scheduled_message)
    end
  end
end
