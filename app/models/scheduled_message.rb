class ScheduledMessage < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :created_by, polymorphic: true

  has_many_attached :files

  enum :status, { pending: 0, sent: 1, failed: 2, cancelled: 3 }

  validates :content, presence: true, unless: -> { files.attached? }
  validates :scheduled_at, presence: true
  validate :scheduled_at_in_future, on: :create

  scope :sendable, -> { pending.where(scheduled_at: 3.days.ago..Time.current) }

  private

  def scheduled_at_in_future
    return if scheduled_at.blank?

    errors.add(:scheduled_at, 'must be in the future') if scheduled_at <= Time.current
  end
end
