require "http/server"
require "http/client"
require "./scraper"
require "json"
require "sqlite3"
require "./Models/Bike"
require "xml"

def scrape_data
  headers = HTTP::Headers.new
  headers["Referer"] = "https://bush-daisy-tellurium.glitch.me/"
  url = "https://bush-daisy-tellurium.glitch.me"
  response = HTTP::Client.get(url, headers: headers)
  html = response.body

  parsed = XML.parse_html(html)
  parsed.xpath_nodes("//div[@class='content']").each do |div|
    div.xpath_nodes("./h3").each do |h3|
      puts h3.text
    end
    div.xpath_nodes("./p").each do |p|
      puts p.text
    end
    div.xpath_nodes("./div[@class='price']").each do |price|
      puts price.text
    end
  end

  return html
end

test_data = scrape_data

# pp! test_data

# bike = Bike.new(1, "Bike 1", "Description 1", 29.99, local_time)
# bike2 = Bike.new(2, "Bike 2", "Description 2", 12.99, local_time)
# bike3 = Bike.new(3, "Bike 3", "Description 3", 14.99, local_time)

# bikes = [bike, bike2, bike3]

# def insert_bikes(bikes)
#   DB.open "sqlite3:bikes.db" do |db|
#     bikes.each do |bike|
#       db.exec "INSERT INTO bikes (bike_id, name, description, price, created_at) VALUES (?, ?, ?, ?, ?)",
#         bike.bike_id, bike.name, bike.description, bike.price, bike.created_at
#     end
#   end
# end

# Database query and grouping
def group_bikes_by_name
  bikes_by_name = [] of Bike

  DB.open "sqlite3:bikes.db" do |db|
    # Query to group bikes by name
    db.query "
        SELECT * FROM bikes
      " do |bike_results|
      bike_results.each do
        bike = Bike.new(
          bike_id: bike_results.read(Int32),
          name: bike_results.read(String),
          description: bike_results.read(String),
          price: bike_results.read(Float64),
          created_at: bike_results.read(Time),
        )

        bikes_by_name << bike
      end
    end
  end

  bikes_by_name
end

# bike = Bike.new("Bike 1", "Description 1", 19.99, Time.local, Time.local)
# bike2 = Bike.new("Bike 2", "Description 2", 29.99, Time.local, Time.local)
# bike3 = Bike.new("Bike 3", "Description 3", 39.99, Time.local, Time.local)

# bikes = [bike, bike2, bike3]

# Shared data structure for the scraper
scraper_data = {} of String => String
data_lock = Mutex.new

# Background scraper task
spawn do
  loop do
    begin
      local_time = Time.local
      # Scrape data and update the shared data structure
      # data = scrape_data
      data_lock.synchronize do
        # scraper_data.clear
        # scraper_data.merge!(data)
      end
      # puts "Scraped data updated: #{scraper_data.to_json}"
      puts "Scraped data updated: #{local_time}"
    rescue ex : Exception
      puts "Error in scraper: #{ex.message}"
    end

    # Sleep for 60 seconds before scraping again
    sleep 5.seconds
  end
end

server = HTTP::Server.new do |context|
  if context.request.path == "/"
    # insert_bikes(bikes)
    # Serve the static index.html
    index_file = "./public/index.html"
    if File.exists?(index_file)
      context.response.content_type = "text/html"
      context.response.print File.read(index_file)
    else
      context.response.status_code = 500
      context.response.print "500 Internal Server Error: index.html not found"
    end
  elsif context.request.path == "/scraped-data"
    grouped_bikes = group_bikes_by_name
    # Return the latest scraped data as JSON
    data_lock.synchronize do
      context.response.content_type = "application/json"
      context.response.print grouped_bikes.to_json
    end
  else
    context.response.status_code = 404
    context.response.print "404 Not Found"
  end
end

# Start the server
port = 9000
puts "Server running on http://localhost:#{port}"
server.listen(port)
