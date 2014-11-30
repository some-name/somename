require 'sinatra'
require 'pg'

db = PGconn.connect("localhost", "5432", "", "", "somename")
db.exec("CREATE TABLE IF NOT EXISTS urls (
	id  BIGSERIAL PRIMARY KEY,
	url TEXT UNIQUE
);")

get '/' do
	#homepage/newurlpage
	erb :index
end

get '/:short' do |id|
	#look up short url id and redirect to full url
	id = id.to_i(36)
	url = db.exec("select exists(select * from urls where id = $1);", [id])
	if url[0]["exists"] == "f"
		return "something funky is going on here...
		<br> <a href='/'>go home?</a>"
	end
	url = db.exec("SELECT * FROM urls WHERE id = $1;", [id])
	redirect url[0]['url'], "MAGIC"
end

get '/add?/?' do
	redirect '/'
end

post '/add/' do
	#add url
	url = params[:url]#make sure the url isn't pointing at somena.me
	id = db.exec("select exists(select * from urls where url = $1);", [url])
	if id[0]["exists"] == "t"
		id = db.exec("select id from urls where url = $1;", [url])
	else
		id = db.exec("insert into urls (url) values ($1) returning id;", [url])
	end
	id = id[0]["id"].to_i.to_s(36)
	short_url = "http://somena.me/#{id}"
	erb :add, :locals => { :url => url, :short_url => short_url }
end