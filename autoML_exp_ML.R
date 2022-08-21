
df <- openintro::loans_full_schema

library(tidyverse)
df <- df %>% select(-emp_title)

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
                  project_name = "autoML_r_py")

perf_metr <- h2o.performance(aml@leader, test)
perf_metr

lb <- aml@leaderboard
print(lb, n = nrow(lb))

lb <- h2o.get_leaderboard(object = aml, extra_columns = "ALL")
lb

xgb_b = h2o.get_best_model(aml, algorithm = "xgboost", criterion = "rmse")
xgb_b
xgb_b@allparameters$max_depth # 3
xgb_b@allparameters$learn_rate # .3

h2o.learning_curve_plot(xgb_b)
h2o.shap_summary_plot(xgb_b, test)

gbm_b = h2o.get_best_model(aml, algorithm = "gbm", criterion = "rmse")
gbm_b
gbm_b@allparameters$max_depth # 6
gbm_b@allparameters$learn_rate # .1

h2o.learning_curve_plot(gbm_b)
h2o.shap_summary_plot(gbm_b, test)


h2o.varimp_plot(xgb_b) # same as py results
h2o.varimp_plot(gbm_b) # gbm suggests balance is almost as important as installment

library(patchwork)
shap_plots <- h2o.shap_summary_plot(gbm_b, test) / h2o.shap_summary_plot(xgb_b, test)
shap_plots + plot_annotation(title = "2 of the best unstacked models from the H2O AutoML || GBM & XGBoost",
                             subtitle = "Shap Summary Plots")

exa <- h2o.explain(aml, test)
exa

exm <- h2o.explain(aml@leader, test)
exm


h2o.ice_plot(gbm_b, test, "installment")
h2o.ice_plot(gbm_b, test, "balance")

h2o.ice_plot(xgb_b, test, "installment")
h2o.ice_plot(xgb_b, test, "balance")


pw_p <- (h2o.ice_plot(gbm_b, test, "installment") | h2o.ice_plot(gbm_b, test, "balance")) / (h2o.ice_plot(xgb_b, test, "installment") | h2o.ice_plot(xgb_b, test, "balance"))
pw_p + plot_annotation(title = "2 of the best unstacked models from the H2O AutoML || GBM & XGBoost",
                      subtitle = "2 Most important variables || installement & balance")

h2o.shutdown()
