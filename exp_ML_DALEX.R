
library(tidyverse)
df <- openintro::loans_full_schema %>% select(-emp_title)

library(h2o)
h2o.init()
df <- as.h2o(df)
h2o.describe(df)
y <- "loan_amount"
splits <- h2o.splitFrame(df, ratios = 0.8, seed = 666)
train <- splits[[1]]
test <- splits[[2]]
aml <- h2o.automl(y = y,
                  training_frame = train,
                  leaderboard_frame = test,
                  max_runtime_secs = 666,
                  seed = 666,
                  project_name = "autoML_r_py_dalex")
perf_metr <- h2o.performance(aml@leader, test)
perf_metr



# explain h2o autoML ------------------------------------------------------
library(DALEXtra)
h2o_aML_explainer <- explain_h2o(aml,
                                 data = test,
                                 y = test$loan_amount,
                                 label = "h2o_exp")

modelDown::modelDown(h2o_aML_explainer,
                     output_folder = "h2o_aML_explainer_output")

h2o.shutdown()



rm(list = ls(all.names = TRUE))
gc() 



# explain tidymodels xgboost ----------------------------------------------
df <- openintro::loans_full_schema %>% select(-emp_title)
library(tidymodels)
set.seed(666)
tt_split <- initial_split(df, 
                          prop = .8)
train <- training(tt_split) 
test <- testing(tt_split)
xgb_fit <- boost_tree(min_n = 41,
                      trees = 131,
                      tree_depth = 3,
                      learn_rate = .3) %>%
  set_mode("regression") %>%
  set_engine("xgboost") %>%
  fit(loan_amount ~ ., data = train)
tidy_models_explainer <- explain_tidymodels(xgb_fit, data = test,
                                            y = test$loan_amount)
modelDown::modelDown(tidy_models_explainer,
                     output_folder = "tidy_models_explainer_output")
