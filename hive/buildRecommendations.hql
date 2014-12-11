source config.hql;

CREATE TABLE gamestats(
  uid STRING,
  appid INT,
  name STRING,
  hoursplayed FLOAT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t' STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH '../data/games-${id}-${depth}.csv' INTO TABLE gamestats;

CREATE TABLE pairs AS
SELECT
  uid,
  pairid,
  appid1,
  name1,
  appid2,
  name2,
  hoursplayed,
  (maxhours - (maxhours - minhours)) AS score
FROM
(
  SELECT
    g1.uid AS uid,
    CONCAT(g1.appid, g2.appid) AS pairid,
    g1.appid AS appid1,
    g1.name AS name1,
    g2.appid AS appid2,
    g2.name AS name2,
    CASE
      WHEN g1.hoursplayed > g2.hoursplayed
      THEN g1.hoursplayed
      ELSE g2.hoursplayed
    END AS maxhours,
    CASE
      WHEN g1.hoursplayed < g2.hoursplayed
      THEN g1.hoursplayed
      ELSE g2.hoursplayed
    END AS minhours,
    userscores.hoursplayed as hoursplayed
  FROM 
    gamestats g1,
    gamestats g2,
    (SELECT * FROM gamestats WHERE uid = ${id}) userscores
  WHERE
    g1.appid != g2.appid
    AND g1.uid = g2.uid
    AND g1.appid = userscores.appid
    AND g2.appid NOT IN (SELECT appid FROM gamestats WHERE uid = ${id})
) A;

CREATE TABLE recommendations AS
SELECT
  appid2 as appid,
  name2 as name,
  AVG((1+hoursplayed) * (1+score)) as score
FROM pairs 
GROUP BY
  appid2,
  name2;