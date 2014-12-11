GameRecommender
=============

This is an experimental videogame recommendation program using free data collected
from [Steam](http://store.steampowered.com/).

There are two engines, one in Hive, and one in Pig. Each
is in its own subdirectory. The wrapper functions are in Ruby.

# Methods

## Getting the Data

Steam has a free RESTful API that allows anyone to access user
data, as long as they know the user's ID and the user in question
has their player data publicly available. 

A ruby script reads a seed ID and a recursion depth
from a config.json file, and then collects the games a user
has played starting with the seed user and then branching out
n=depth levels for each of that user's friends. The script was
only saves each user once, regardless of how many
people in the social network are friends with that person.

For example: Bob is my seed ID. Bob is friends with Joe, and
Joe is friends with Thomas. Thomas and Bob are not friends.
If I set config.json to have a depth of 2, getData.rb will pull
all of Bob's player data and all of Joe's player data. If I
set config.json to have a depth of 3, I will also pull Thomas'
data along with Bob and Joe. 4 would pull all of Thomas' friends
as well, etc. A depth of 1 only pulls data for the seed. A depth
of 0 pulls nothing.

*Warning*: each level of depth exponentially increases the amount
of data pulled, the time it takes to retrieve it, and the time
it takes to build recommendations off of it.

Data files are saved in JSON format for pig, and CSV for hive:

    /data/<SEED-ID>-<RECURSION-DEPTH>.json
    /data/<SEED-ID>-<RECURSION-DEPTH>.csv

## General Recommendation Algorithm

1. Create a list of game pairs for every user. Only include pairs
where the seed user has played at least 1 of the two games.

    Example pair: 
        uid:123, id1:1, name1:Skyrim, hours1:30, userHrsPlayed: 5
                 id2:2, name2:TF2,    hours2:60

2. Calculate a related score for this pair based on hours played
for each game.
    
        score = max_hours_played - 
                (max_hours_played - min_hours_played)

3. Get average score for each game pair across all users.

4. For each pair, multiply the score by hours the seed user
played the first game in the pair. (Add one to both to keep
games played for less than one hour from shrinking in value
compared to games played for over an hour.)

        recommendation = (1+score) * (1+userHrsPlayed)

5. Split the pairs, keeping the final score for both games, and 
filter out any games the user has already played.
    
6. Save a list of the unplayed games sorted by score descending.


# Usage

1. Install [Ruby](https://www.ruby-lang.org/en/),
[Pig](http://pig.apache.org/) and [Hive](http://hive.apache.org/).

2. Create a config.json containing a steam64 ID and a depth.

        {"seed": "76561197968575517", "depth": 2}

3. Build a dataset: `ruby populateBaseData.rb`
    
4. Run both engines. You can use the included script 
`ruby runEngines.rb` or run them from the command line with
your own specific options.

5. `ruby printResults.rb` to output the results to the Terminal.


# Limitations

Games are considered related if a single user played both
of them. Games are considered to be more highly related if a user
plays them both for a high number of hours. This is built on top
of the (generally faulty) assumption that users only like one
type of game, and puts short games at a disadvantage compared to
long ones.

Each of these scripts was only tested on one laptop,
and may or may not be compatible with other OS's or
Pig/Hive setups.