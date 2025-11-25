json.array! @chat_agents do |chat_agent|
  json.partial! 'api/v1/models/chat_agent', chat_agent: chat_agent
end
