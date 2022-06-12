
df <- openintro::loans_full_schema

library(h2o)
h2o.init(nthreads = -1, max_mem_size = "24G")

aml_df <- as.h2o(df)

h2o.describe(aml_df)

dplyr::n_distinct(df$emp_title) # 4742

# emp_title very problematic with Cardinality 4411 -- drop 
# state might also be problematic
# sub_grade might also be problematic

library(tidyverse)
df <- df %>% select(-emp_title)

aml_df <- as.h2o(df)

h2o.describe(aml_df)

y <- "loan_amount"

splits <- h2o.splitFrame(aml_df, ratios = 0.8, seed = 666)
train <- splits[[1]]
test <- splits[[2]]

aml <- h2o.automl(y = y,
                  training_frame = train,
                  leaderboard_frame = test,
                  max_runtime_secs = 1200,
                  seed = 666,
                  project_name = "autoML")

print(aml@leaderboard)

model_ids <- as.data.frame(aml@leaderboard$model_id)[,1]
se <- h2o.getModel(grep("StackedEnsemble_AllModels", model_ids, value = TRUE)[1])
metalearner <- h2o.getModel(se@model$metalearner$name)

h2o.varimp(metalearner)
h2o.varimp_plot(metalearner)

gbm <- h2o.getModel(grep("GBM", model_ids, value = TRUE)[1])
h2o.varimp(gbm)
h2o.varimp_plot(gbm)
