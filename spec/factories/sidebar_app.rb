# frozen_string_literal: true

FactoryBot.define do
  factory :sidebar_app do
    sequence(:title) { |n| "Sidebar App #{n}" }
    url { 'https://example.com/app' }
    display_location { 'apps_menu' }
    position { 0 }
    icon { 'i-lucide-app-window' }
    allowed_roles { [] }
    user
    account
  end
end
