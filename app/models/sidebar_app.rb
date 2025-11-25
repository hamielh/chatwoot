# == Schema Information
#
# Table name: sidebar_apps
#
#  id               :bigint           not null, primary key
#  allowed_roles    :text             default([]), is an Array
#  display_location :string           default("apps_menu"), not null
#  icon             :string           default("i-lucide-app-window")
#  position         :integer          default(0), not null
#  title            :string           not null
#  url              :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  user_id          :bigint
#
# Indexes
#
#  index_sidebar_apps_on_account_id  (account_id)
#  index_sidebar_apps_on_user_id     (user_id)
#
class SidebarApp < ApplicationRecord
  DISPLAY_LOCATIONS = %w[root apps_menu].freeze

  belongs_to :user
  belongs_to :account

  validates :title, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :display_location, presence: true, inclusion: { in: DISPLAY_LOCATIONS }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :icon, presence: true

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :for_role, ->(role) { where('allowed_roles = ARRAY[]::text[] OR ? = ANY(allowed_roles)', role) }
  scope :in_root, -> { where(display_location: 'root') }
  scope :in_apps_menu, -> { where(display_location: 'apps_menu') }
end
