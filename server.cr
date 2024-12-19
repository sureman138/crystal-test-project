require "http/server"
require "http/client"
require "./scraper"
require "json"
require "sqlite3"
require "./Models/Bike"
require "xml"

# scrape data from https://bush-daisy-tellurium.glitch.me and insert into database
def scrape_data
  bike_name = ""
  bike_description = ""
  bike_price = ""
  local_time = Time.local

  headers = HTTP::Headers.new
  headers["Referer"] = "https://bush-daisy-tellurium.glitch.me/"
  url = "https://bush-daisy-tellurium.glitch.me"
  response = HTTP::Client.get(url, headers: headers)
  html = response.body

  begin
    parsed = XML.parse_html(html)
    parsed.xpath_nodes("//div[@class='content']").each do |div|
      div.xpath_nodes("./h3").each do |h3|
        bike_name = h3.text
      end
      div.xpath_nodes("./p").each do |p|
        bike_description = p.text
      end
      div.xpath_nodes("./div[@class='price']").each do |price|
        cleaned_str = price.text.gsub(/[^\d.]/, "")
        bike_price = cleaned_str.to_f64
      end
      # bike_id = get_bike_id
      bike = Bike.new(bike_name, bike_description, bike_price, local_time)
      insert_bike(bike)
    end
  rescue ex : Exception
    puts "Error in scraper: #{ex.message}"
  end
  return html
end

# Database insertion
def insert_bike(bike)
  DB.open "sqlite3:bikes.db" do |db|
    db.exec "INSERT INTO bikes (name, description, price, created_at) VALUES (?, ?, ?, ?)",
      bike.name, bike.description, bike.price, bike.created_at
  end
end

# Database query and grouping
def group_bikes_by_name
  bikes_by_name = [] of Bike

  DB.open "sqlite3:bikes.db" do |db|
    db.query "
        SELECT * FROM bikes
      " do |bike_results|
      bike_results.each do
        bike = Bike.new(
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

data_lock = Mutex.new

# Background scraper task
spawn do
  loop do
    begin
      local_time = Time.local
      data_lock.synchronize do
        scrape_data
      end
      puts "Scraped data updated: #{local_time}"
    rescue ex : Exception
      puts "Error in scraper: #{ex.message}"
    end

    # Sleep for 60 seconds before scraping again
    sleep 60.seconds
  end
end

server = HTTP::Server.new do |context|
  if context.request.path == "/"
    # Serve the static index.html
    index_file = "./public/index.html"
    if File.exists?(index_file)
      context.response.content_type = "text/html"
      context.response.print File.read(index_file)
    else
      context.response.status_code = 500
      context.response.print "500 Internal Server Error: index.html not found"
    end
  elsif context.request.path == "/get-bike-prices"
    grouped_bikes = group_bikes_by_name
    # Return the latest scraped data as JSON
    data_lock.synchronize do
      context.response.content_type = "application/json"
      context.response.print grouped_bikes.to_json
    end
  elsif context.request.path == "/manual-scrape"
    # Trigger the scraper to scrape data
    scrape_data
    context.response.content_type = "text/plain"
    context.response.print "Scraping Completed".to_json
  else
    context.response.status_code = 404
    context.response.print "404 Not Found"
  end
end

port = 9000
puts "Server running on http://localhost:#{port}"
server.listen(port)
