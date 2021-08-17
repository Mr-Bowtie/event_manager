require 'csv'
require 'time'
require 'erb'
require 'google/apis/civicinfo_v2'

DAY_CONVERSION = { 0 => 'Monday', 1 => 'Tuesday', 2 => 'Wednesday', 3 => 'Thursday', 4 => 'Friday', 5 => 'Saturday', 6 => 'Sunday' }

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_date_time(dirty_date)
  date, time = dirty_date.split(' ')
  date_array = date.split('/')
  year = date_array.pop
  date_array.unshift(year)
  date = date_array.join('/')
  "#{date} #{time}"
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

# takes any array and returns a 3 element array containing the 3 most repeated elements in the given array
def top_three(array)
  el_count = {}
  array.each do |h|
    el_count.has_key?(h) ? el_count[h] += 1 : el_count[h] = 1
  end
  array.uniq.sort_by { |h| el_count[h] }.reverse.shift(3)
end

# takes an array of numbers generated from Date#wday and returns their equivalent as a string
def day_converter(days)
  days.map { |daynum| DAY_CONVERSION[daynum] }
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

hours = []
# an array of numbers (0-6) corresponding to days (monday is 0)
days = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  number = clean_phone_number(row[:homephone])
  reg_date_time = Time.parse(clean_date_time(row[:regdate]))
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  hours << reg_date_time.hour
  days << reg_date_time.wday
end
puts "Personalized letters generated\n\n"
puts "Peak registration hours are #{top_three(hours)}"
puts "Most active registration days are #{day_converter(top_three(days))}"
