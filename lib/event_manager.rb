require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'pry'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  clean_number = number.gsub(/[^0-9]/, '')
  if clean_number.length == 11 && clean_number[0] == '1'
    clean_number = clean_number.delete_prefix('1')
  elsif clean_number.length == 10
    clean_number
  else
    'Invalid number'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody'],
    ).officials
  rescue
    'You can find your representative by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

template_letter = File.read('form_letter.html.erb')
erb_template = ERB.new template_letter

puts 'Event Manager Initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol,
)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  number = clean_phone_number(row[:homephone])

  #  legislators = legislators_by_zipcode(zipcode)

  #  form_letter = erb_template.result(binding)

  #  save_thank_you_letter(id, form_letter)
  puts "#{name} #{number}"
end
