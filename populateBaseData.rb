require 'json'
require 'open-uri'
require 'active_support/core_ext/hash'
require 'pp'

def getSteamXML(url)
  res = open(url)
  xml = ""
  res.each_line {|line| xml += line}
  xml.delete!("\r\n").delete!("\t")
  begin
    hash = Hash.from_xml(xml)
  rescue
    hash = false
  end
  return hash
end

def getGames(id)
  games = getSteamXML("http://steamcommunity.com/profiles/#{id}/games?tab=all&xml=1")
  unless(games.nil? || !games)
    begin
      games = games["gamesList"]["games"]["game"]
      output = []
      games.each {|game|
        if(!game["hoursOnRecord"])
          next
        end
        output.push({
          "user" => id,
          "appID" => game["appID"].to_i,
          "name" => game["name"],
          "hoursOnRecord" => game["hoursOnRecord"].to_f
        })
      }
    rescue StandardError => e
      pp e
    end
  end
  return output
end

def getFriends(id)
  friends = getSteamXML("http://steamcommunity.com/profiles/#{id}/friends/?xml=1&l=english")
  unless(friends.nil? || !friends)
    begin
      friends = Array(friends["friendsList"]["friends"]["friend"])
    rescue
      friends = false
    end
  end
  return friends
end

def recursiveGet(id, depth)
  if(depth == 1)
    return getGames(id)
  else
    games = getGames(id)
    friends = getFriends(id)
    if(friends)
      friends.each{ |friend|
        friendGames = recursiveGet(friend, depth-1)
        if(friendGames)
          games.concat(friendGames)
        end
      }
    end
    return games
  end
end

def writeData(filename, games)
  File.open(filename+'.json', 'w') {|file| file.truncate(0) }
  File.open(filename+'.json', 'a+') {|file|
    games.each {|game|
      file.puts game.to_json
    }
  }
  File.open(filename+'.csv', 'w') {|file| file.truncate(0) }
  File.open(filename+'.csv', 'a+') {|file|
    games.each {|game|
      file.puts game.values.join("\t")
    }
  }  
end

config = JSON.parse(File.open('config.json', 'rb').read)
games = recursiveGet(config['seed'], config['depth'])
writeData("data/games-#{config['seed']}-#{config['depth']}", games)