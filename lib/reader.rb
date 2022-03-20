class Reader
  class << self
    def start(filename)
      unless File.exists?(filename)
        puts "CSV file does not exists." 
        return
      end

      file = CSV.read((filename), headers: true)
      puts file
    end
  end
end