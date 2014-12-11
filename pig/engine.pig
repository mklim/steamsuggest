-- calculate related scores for all games
-- must pass a param file containing the seed id and depth
-- $ pig -x local -param_file params.conf getPref.pig

stats1 = LOAD '../data/games-$id-$depth.json'
  USING  JsonLoader('user:chararray, appid:int, name:chararray, hoursOnRecord:float');
stats2 = FOREACH stats1 GENERATE *;

-- pair all games with each other
crossed = CROSS stats1, stats2;

-- only include pairs for same user
-- don't include games paired with themselves
-- only include each pair once
pairs = FILTER crossed BY (
  stats1::user == stats2::user
  and stats1::appid != stats2::appid
);
pairs = ORDER pairs BY stats1::appid;


-- we're only interested in pairs where our base user has played one of the games, so filter down on that


-- calculate list of games played by user
usergames = FILTER stats1 BY (user == '$id');
usergames = ORDER usergames BY hoursOnRecord DESC;

-- inner join on the rest of our games to filter down to ones where our seed user has played at least one of them
pairs = JOIN usergames BY appid, pairs BY stats1::appid;

-- -- now that we've matched left column to user games, filter down so each unique pair only listed once
-- pairs = FILTER pairs BY (stats1::appid > stats2::appid);

-- next, get max and min playtime for each pair
pairs = FOREACH pairs GENERATE
  stats1::user AS user,
  (chararray)stats1::appid AS appid1:chararray,
  stats1::name AS name1,
  (chararray)stats2::appid AS appid2:chararray,
  stats2::name AS name2,
  usergames::hoursOnRecord AS hoursPlayed,
  (stats1::hoursOnRecord > stats2::hoursOnRecord ?
    stats1::hoursOnRecord : stats2::hoursOnRecord) AS maxplayed,
  (stats1::hoursOnRecord < stats2::hoursOnRecord ?
    stats1::hoursOnRecord : stats2::hoursOnRecord) AS minplayed;

-- then, calculate the score for each pair. high scoring game pairs are games where both games have high playtimes.
pairs = FOREACH pairs GENERATE
  user,
  (maxplayed - (maxplayed - minplayed)) AS score,
  hoursPlayed,
  appid1,
  name1,
  appid2,
  name2;

-- now calculate the average score across all users for game pairs
grouped = GROUP pairs BY (chararray)CONCAT(appid1, appid2);
averages = FOREACH grouped GENERATE
  group AS pairid:chararray,
  (float)AVG(pairs.score) AS score:float,
  FLATTEN(pairs.hoursPlayed) AS hoursPlayed,
  FLATTEN(pairs.appid1) AS appid1:chararray,
  FLATTEN(pairs.name1) AS name1:chararray,
  FLATTEN(pairs.appid2) AS appid2:chararray,
  FLATTEN(pairs.name2) AS name2:chararray;
-- averages: {pairid: chararray,score: float,appid1: chararray,name1: chararray,appid2: chararray,name2: chararray}
-- averages = ORDER averages BY score DESC;


-- now, split pairs and give each game a final score, taking user pref into account
finalscores = FOREACH averages GENERATE 
  appid2 AS appid,
  ((1+score) * (1+hoursPlayed)) AS score,
  name2 AS name;
-- remove all games user has already tried
recommends = JOIN finalscores BY appid LEFT OUTER, usergames BY (chararray)appid;
recommends = FILTER recommends BY usergames::user IS null;
recommends = FOREACH recommends GENERATE
  finalscores::appid as appid,
  finalscores::score as score,
  finalscores::name as name;
recommends = GROUP recommends BY appid;
recommends = FOREACH recommends GENERATE 
  group as appid,
  AVG(recommends.score) as score,
  FLATTEN(recommends.name) as name;

-- sort by highest to least recommended, limit to 100, save
result = DISTINCT recommends;
result = ORDER result BY score DESC;
result = LIMIT result 100;

STORE result 
    INTO 'result' 
    USING JsonStorage();