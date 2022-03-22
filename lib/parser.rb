require 'csv'
require 'httparty'

REQUIRED_KEYS = ['Email','First Name','Last Name','Residential Address Street','Residential Address Locality',
  'Residential Address State','Residential Address Postcode','Postal Address Street',
  'Postal Address Locality','Postal Address State','Postal Address Postcode']

class Parser
  class << self
    def start(filename, output)
      unless File.exists?(filename)
        puts "CSV file does not exists." 
        return
      end

      CSV.open(output, "w") do |csv|
        csv << REQUIRED_KEYS

        CSV.foreach((filename), headers: true) do |row|
          print "."
          
          valid = RowValidation.new(row).valid_row?
          next unless valid

          csv << REQUIRED_KEYS.map { |m| row[m] }.join(', ').split(', ')
        end
      end

      puts "\nDone parsing, output file is #{output}"
    end
  end
end

class RowValidation
  # found this API to check Australia's postal codes rather than using geocoder gems which is also not accurate
  AU_POSTAL_API = "https://api.beliefmedia.com/postcodes"

  attr_reader :row

  def initialize(row)
    @row = row
  end

  def valid_row?
    return false if invalid_values?
    return false unless valid_geocode_pair?
    true
  end

  private

  def invalid_values?
    return REQUIRED_KEYS.map { |key| row[key].nil? || row[key].empty? }.include?(true)
  end

  def valid_geocode_pair?
    ['Residential Address', 'Postal Address'].each do |location|
      response = call_au_api(location)
      return false unless response.success?

      data = JSON.parse(response.body)['data']
      localities = data['locality'].split(', ').map(&:upcase)
      state = data['state'].upcase

      return false unless localities.include?(row["#{location} Locality"].upcase) || state != row["#{location} State"]
    end
    true
  end

  def call_au_api(location)
    postal_code = [location, 'Postcode'].join(' ')
    base_uri = [AU_POSTAL_API, "#{row[postal_code]}.json"].join('/')

    HTTParty.get(base_uri)
  end
end
