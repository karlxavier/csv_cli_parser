require 'csv'
require 'httparty'

class Parser
  # found this API to check Australia's postal codes rather than using geocoder gems which is also not accurate
  AU_POSTAL_API = "https://api.beliefmedia.com/postcodes"
  REQUIRED_KEYS = ['Email','First Name','Last Name','Residential Address Street','Residential Address Locality',
                   'Residential Address State','Residential Address Postcode','Postal Address Street',
                   'Postal Address Locality','Postal Address State','Postal Address Postcode']

  class << self
    attr_reader :row

    def start(filename, output)
      unless File.exists?(filename)
        puts "CSV file does not exists." 
        return
      end

      CSV.open(output, "w") do |csv|
        csv << REQUIRED_KEYS

        CSV.foreach((filename), headers: true) do |row|
          print "."
          @row = row
          next unless valid_row? || valid_geocode_pair?

          csv << REQUIRED_KEYS.map { |m| row[m] }.join(', ').split(', ')
        end
      end

      puts "\nDone parsing, output file is #{output}"
    end

    private

    def valid_row?
      REQUIRED_KEYS.each do |key|
        return false if row[key].nil? || row[key].empty?
      end
    end

    def valid_geocode_pair?
      ['Residential Address' 'Postal Address'].each do |location|
        response = call_au_api(location)
        return false unless response.success?

        data = JSON.parse(response.body)['data']
        localities = data['locality'].split(', ').map(&:upcase)
        state = data['state'].upcase

        return false unless localities.include?(row["#{location} Locality"].upcase)
        return false unless state != row["#{location} State"]
      end
      true
    end

    def call_au_api(location)
      postal_code = [location, 'Postcode'].join(' ')
      base_uri = [AU_POSTAL_API, "#{row[postal_code]}.json"].join('/')

      HTTParty.get(base_uri)
    end

  end
end
