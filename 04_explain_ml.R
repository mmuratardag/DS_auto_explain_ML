df <- openintro::loans_full_schema

library(tidyverse)
df <- df %>% select(-emp_title)

library(tidymodels)
set.seed(666)
tt_split <- initial_split(df, 
                          prop = .8)
train <- training(tt_split) %>% drop_na()
test <- testing(tt_split) %>% drop_na()

xgb_fit <- boost_tree(min_n = 41,
                      trees = 123,
                      tree_depth = 6) %>%
  set_mode("regression") %>%
  set_engine("xgboost") %>%
  fit(loan_amount ~ ., data = train)

library(DALEX)
explainer <- DALEX::explain(model = xgb_fit,
                            data  = train, 
                            y = train$loan_amount,
                            label = "XGBoost")

new_observations <- test[1:10, ] %>% as.data.frame()
rownames(new_observations) <- paste0("id", 1:10)

library(modelStudio)
modelStudio::modelStudio(explainer, new_observations)
