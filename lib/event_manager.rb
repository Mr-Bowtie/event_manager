puts "Event Manager Initialized!"

lines = File.readlines("event_attendees.csv")
lines.each do |file|
  columns = line.split(",")
  p columns
end
