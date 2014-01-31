require 'uri'
require 'net/http'
require 'json'
require './config.rb'

class App
	def initialize(id, name)
		@id = id
		@name = name
	end
	attr_reader :id
	attr_reader :name
	def to_s
		"#{@id}:#{@name}"
	end
end

def get_app_names
	uri = URI("http://api.steampowered.com/ISteamApps/GetAppList/v2")
	res = Net::HTTP.get_response(uri)
	return nil unless res.is_a?(Net::HTTPSuccess)
	$app_names = Hash.new
	data = JSON.parse(res.body)
	data["applist"]["apps"].each { |x|
		$app_names[x["appid"].to_i] = x["name"]
	}
end

def get_steamid(vanity_name)
	uri = URI("http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/")
	uri.query = URI.encode_www_form("format" => "json", "vanityurl" => vanity_name, "key" => $apikey)
	res = Net::HTTP.get_response(uri)
	return nil unless res.is_a?(Net::HTTPSuccess)

	puts "Looked up user"

	data = JSON.parse(res.body)
	return nil unless data["response"]["success"] == 1

	puts "Got steam id for user:"
	steamid = data["response"]["steamid"]
	puts steamid
	return steamid
end

def get_game_list(steamid)
	uri = URI("http://api.steampowered.com/IPlayerService/GetOwnedGames/v1/")
	uri.query = URI.encode_www_form("format" => "json", "steamid" => steamid, "key" => $apikey, "include_played_free_games" => true, "include_appinfo" => true)
	res = Net::HTTP.get_response(uri)
	return nil unless res.is_a?(Net::HTTPSuccess)

	data = JSON.parse(res.body)
	puts data["response"]["games"]
	return data["response"]["games"].collect { |x| App.new(x["appid"], $app_names[x["appid"].to_i]) }
end

def get_coop_game_list(user_vanity)
	steamid = get_steamid(user_vanity)
	return nil if steamid.nil?

	game_list = get_game_list(steamid)
	#print game_list
	#puts
	uri = URI("http://store.steampowered.com/api/appdetails/")
	uri.query = URI.encode_www_form("appids" => game_list.collect{ |x| x.id }.join(","), "filters" => "categories")
	res = Net::HTTP.get_response(uri)
	return nil unless res.is_a?(Net::HTTPSuccess)

	data = JSON.parse(res.body)
	#puts data
	coop_games = game_list.select { 
		|x| 
		puts "checking #{x.id}:#{x.name}"
		game_data = data[x.id.to_s]["data"]
		next false unless game_data.is_a?(Hash)
		next false if game_data["categories"].nil?
		puts game_data["categories"]
		(not (game_data["categories"].select { |y|
			y["id"] == "9" || y["id"] == "24"
		}.empty?))
	}
	puts coop_games
end

get_app_names
#get_coop_game_list "ComputerDruid"
get_coop_game_list "8j8j8j"

