# crystal-test-project

## Architecture Decisions for Web Scraper and HTTP Server
Created the scraper logic to use the xml parse_html function built in to crystal. Looped through the "content" class divs and pulled the price, name, and description, then stored those values to the database along with current timestamp

Http server uses the built-in library within crystal as well, and just handles the three simple requests, as well as 404

## Database Table Design
Basically kept database design as simple as possible. Used the sqlite3 package referenced in the crystal website documentation. Just one "bikes" table in the schema that contains name, price, description, created_at. If I were building this out in more detail, I'd definitely add a products or bikes table and a price table separately, possibly with an explicit foreign key connecting the two tables, but at least a relation column. 

## File Overview
Pretty straightforward. Have the files generated automatically with the install command (lib, shard.lock, shard.yml), then the public folder containing the index.html, a Models folder containing the Bike class, the database file, then the server file.

## Crystal Learning Resources
The official crystal website has some pretty extensive documentation to get things going initially. I relied on that quite a bit when getting all of the initial scaffolding and database built out. I found myself in the crystal website forums as well, where I found the first example of using the built-in XML library and parse_html function that I ultimately used to scrape and read html data. I did use LLMs (Claude) when trying to figure out gritty details about the language like casting different data types. These tools are great imo when basically trying to be a reference to technical documentation and responses can be quickly verified with puts, pp!, or the crystal web playground. I also just saw there is a reputable linter called Ameba that I did not use but wish I discovered at the beginning.