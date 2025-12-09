json.array! @sidebar_apps do |sidebar_app|
  json.partial! 'api/v1/models/sidebar_app', formats: [:json], resource: sidebar_app
end
