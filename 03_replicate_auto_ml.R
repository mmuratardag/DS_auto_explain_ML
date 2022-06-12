
cores <- parallel::detectCores(logical = F)
doParallel::registerDoParallel(cores = cores-1)

df <- openintro::loans_full_schema

library(tidyverse)
df <- df %>% select(-emp_title)

library(tidymodels)
set.seed(666)
tt_split <- initial_split(df, 
                          prop = .8)
train_set <- training(tt_split)
test_set <- testing(tt_split)

model_recipe <- recipe(loan_amount ~ ., data = train_set) %>%
  step_naomit(everything(), skip = T) %>%
  step_novel(all_nominal(), -all_outcomes()) %>%
  step_normalize(all_numeric(), -all_outcomes()) %>%
  step_dummy(all_nominal(), -all_outcomes()) %>%
  step_zv(all_numeric(), -all_outcomes()) %>%
  step_corr(all_predictors(), threshold = 0.7, method = "spearman")

set.seed(666)
cv_folds <- vfold_cv(train_set, v = 5)

gbm_spec <- 
  boost_tree(min_n = 41,
             trees = 123,
             tree_depth = 6,
  ) %>% 
  set_engine("xgboost") %>% # incompatibility issues with gbm, lightgbm & treesnip lightgbm so xgboost
  set_mode("regression")

gbm_wflow <-
  workflow() %>%
  add_recipe(model_recipe) %>% 
  add_model(gbm_spec)

gbm_res <- 
  gbm_wflow %>% 
  fit_resamples(
    resamples = cv_folds, 
    metrics = metric_set(mae, rsq, rmse),
    control = control_resamples(save_pred = TRUE)
  )

gbm_res %>% collect_metrics(summarize = TRUE)

last_fit(gbm_wflow, 
         split = tt_split,
         metrics = metric_set(mae, rsq, rmse)) %>% collect_metrics()
