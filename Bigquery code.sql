# Using NCAA Basketball data from bigquery public dataset

# Create table in your dataset with the data that you want to use
CREATE TABLE IF NOT EXISTS `bigdatagroup2v1.bigdata.main_data`
AS 
SELECT
     Game_id, field_goals_made, 
  turnovers, offensive_rebounds, 
  defensive_rebounds, free_throws_made, 
  assists, blocks, steals ,win,
   CASE
    WHEN row_num <= 20862  THEN 'training'
    WHEN row_num <= 26822  THEN 'evaluation'
    ELSE 'prediction'
  END AS dataframe
FROM
(
SELECT 
  Game_id, field_goals_made, 
  turnovers, offensive_rebounds, 
  defensive_rebounds, free_throws_made, 
  assists, blocks, steals ,win, ROW_NUMBER() OVER (partition by win) as row_num
 
FROM `bigquery-public-data.ncaa_basketball.mbb_teams_games_sr`
WHERE win is NOT NULL AND
  turnovers  IS NOT NULL AND
  offensive_rebounds IS NOT NULL AND 
  defensive_rebounds  IS NOT NULL AND
  free_throws_made IS NOT NULL AND
  assists  IS NOT NULL AND
  blocks  IS NOT NULL AND
  steals  IS NOT NULL AND
  field_goals_made IS NOT NULL 
)
;

# Create model to predict win
CREATE MODEL IF NOT EXISTS 
  `bigdatagroup2v1.bigdata.win_model1`
OPTIONS 
  (MODEL_TYPE = 'BOOSTED_TREE_CLASSIFIER', 
  learn_rate = 0.1,
  early_stop = TRUE,
  input_label_cols=['win']) AS
SELECT 
  field_goals_made, 
  turnovers, offensive_rebounds, 
  defensive_rebounds, free_throws_made, 
  assists, blocks, steals ,win
FROM `bigdatagroup2v1.bigdata.train_V1`
WHERE win is NOT NULL
AND dataframe <> 'evaluation'
;

# Evaluate the model
SELECT
  *
FROM
  ML.EVALUATE (MODEL `bigdatagroup2v1.bigdata.win_model1`,
    (
    SELECT
      *
    FROM
      `bigdatagroup2v1.bigdata.main_data`
    WHERE
      dataframe = 'evaluation'
    )
  )
  ;

# check feature importance
SELECT *
FROM
  ML.FEATURE_IMPORTANCE(MODEL `bigdatagroup2v1.bigdata.win_model1`)
ORDER BY importance_weight DESC
;
