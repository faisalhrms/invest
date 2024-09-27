json.activity_stream @activity_streams do |activity_stream|
  json.user_name activity_stream.user.full_name
  json.email activity_stream.user.email
  json.action_name activity_stream.action_name
  json.action_datetime activity_stream.action_datetime.strftime("%d-%b-%Y at %I:%M %P")
end