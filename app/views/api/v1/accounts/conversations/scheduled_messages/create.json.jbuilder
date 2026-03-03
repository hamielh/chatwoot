json.id @scheduled_message.id
json.content @scheduled_message.content
json.scheduled_at @scheduled_message.scheduled_at
json.status @scheduled_message.status
json.private @scheduled_message.private
json.created_at @scheduled_message.created_at
json.attachments @scheduled_message.files do |file|
  json.id file.id
  json.filename file.filename.to_s
  json.content_type file.content_type
  json.byte_size file.byte_size
end
