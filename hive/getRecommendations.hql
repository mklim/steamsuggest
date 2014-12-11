source config.hql;

INSERT OVERWRITE LOCAL DIRECTORY 'results'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
  SELECT
    appid,
    name,
    score
  FROM recommendations
  ORDER BY score DESC; 