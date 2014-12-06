require 'sinatra'
require 'pg'

db = PGconn.connect("localhost", "5432", "", "", "somename")
db.exec("CREATE TABLE IF NOT EXISTS urls (
	id  BIGSERIAL PRIMARY KEY,
	url TEXT UNIQUE,
	views BIGINT
);")

get '/' do
	#homepage/newurlpage
	erb :index
end

get '/:short' do |id|
	#look up short url id and redirect to full url
	id = id.to_i(36)
	query = db.exec("select exists(select * from urls where id = $1);", [id])
	if query[0]["exists"] == "f"
		return "something funky is going on here...
		<br> <a href='/'>go home?</a>"
	end
	query = db.exec("SELECT * FROM urls WHERE id = $1;", [id])
	db.exec("UPDATE urls SET views = views + 1 WHERE id = $1;", [id])
	url = query[0]['url'].start_with?("http") ? query[0]['url'] : "http://" << query[0]['url']
	redirect url, "MAGIC"
end

get '/add?/?' do
	redirect '/'
end

post '/add/' do
	#add url
	url = params[:url]#make sure the url isn't pointing at somena.me
	if url =~ /somena\.me/i
		return erb :add, :locals => { :url => "http://somena.me", :short_url => "http://somna.me" }
	end
	id = db.exec("select exists(select * from urls where url = $1);", [url])
	if id[0]["exists"] == "t"
		id = db.exec("select id from urls where url = $1;", [url])
	else
		id = db.exec("insert into urls (url, views) values ($1, 0) returning id;", [url])
	end
	id = id[0]["id"].to_i.to_s(36)
	redirect "/about/#{id}"
end

get '/about/:short' do |id|
	id = id.to_i(36)
	query = db.exec("select exists(select * from urls where id = $1);", [id])
	if query[0]["exists"] == "f"
		return "something funky is going on here...
		<br> <a href='/'>go home?</a>"
	end
	query = db.exec("SELECT * FROM urls WHERE id = $1;", [id])
	short_url = "http://somena.me/#{query[0]['id'].to_i.to_s(36)}"
	views = query[0]['views']
	url = query[0]['url'].start_with?("http") ? query[0]['url'] : "http://" << query[0]['url']
	erb :about, :locals => { :url => url, :short_url => short_url, :views => views }
end







