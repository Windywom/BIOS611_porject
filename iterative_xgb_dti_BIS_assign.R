## XGBoost
library(xgboost)
library(caret)
library(dplyr)
library(utils)
library(tidyverse)
library(ggplot2)
library(lme4)
library(lmerTest)
library(MuMIn)
library(readxl)
library(ParBayesianOptimization)

#setwd("D:/bios-611-project")
runtimes=1
  set.seed(runtimes)
  ## Load behavioral Data
  behav_dat = read_excel("./source_data_DTI/xingweiliaobiao.xlsx",col_names = TRUE)
  ## Load DTI FA Data
  dti_dat = read_excel("./source_data_DTI/DTI_FA.xlsx",col_names = TRUE)


  #train_id = sample(c(1:nrow(dti_dat)), round(nrow(dti_dat)*0.9,0), 
    #                replace = FALSE)
  
  X = dti_dat[,4:ncol(dti_dat)] %>%  as.matrix
  Y = behav_dat$BIS
  #X = dti_dat[train_id,4:ncol(dti_dat)] %>%  as.matrix
  #X_test = dti_dat[-train_id,4:ncol(dti_dat)] %>%  as.matrix
  #Y = behav_dat[train_id,]$BIS
  ncol(X)
  
  ## Tuning Hyperparameters
  ### Create 10 Folds
  folds = createFolds(behav_dat$BIS, k=10)
  #folds = createFolds(behav_dat[train_id,]$BIS, k=10)
  
  ### The function that returns the model evaluation metric we want to optimize
  scoringfunction = function(eta, max_depth, min_child_weight, alpha) {
    #### Set Hyperparameters
    pars <- list( 
      booster = "gbtree",
      eta = eta,
      max_depth = max_depth,
      min_child_weight = min_child_weight,
      #subsample = subsample,
      objective = "reg:squarederror",
      eval_metric = "rmse",
      seed = runtimes*10,
      alpha=alpha
    )
    #X_matrix = as.matrix(X)
    dtrain <- xgb.DMatrix(as.matrix(X),label = Y)
    xgbcv <- xgb.cv(
      params = pars,
      data = dtrain,
      #label = Y,
      nround = 40,
      folds = folds,
      prediction = TRUE,
      showsd = TRUE,
      early_stopping_rounds = 5,
      maximize = FALSE,
      verbose = 0)
    
    print(xgbcv$evaluation_log[xgbcv$best_iteration,])
    
    return(
      list( 
        Score = -min(xgbcv$evaluation_log$test_rmse_mean),
        nrounds = xgbcv$best_iteration
      )
    )
  }
  
  bounds <- list( 
    eta = c(0.01, 0.3),
    max_depth = c(2L, 5L),
    min_child_weight = c(1,5),
    alpha = c(0.1,10)
  )
  
  optObj <- bayesOpt(
    FUN = scoringfunction,
    bounds = bounds,
    initPoints = 10,
    iters.n = 40
  )
  
  pars<- optObj$scoreSummary
  bestpars<-pars[which.max(pars$Score),];

  
  cv_xgboost = function(x,i) {
    training_fold = X[-x, ]
    test_fold = X[x, ]
    xgb = xgboost(data = as.matrix(training_fold), label = Y[-x],
                  #eta =0.3,max_depth = 3,
                  eta = bestpars$eta,max_depth = bestpars$max_depth, 
                  nround=bestpars$nrounds, 
                  #nround=100,
                  #subsample = bestpars$subsample,
                  min_child_weight = bestpars$min_child_weight,
                  alpha = bestpars$alpha,
                  eval_metric = "rmse",
                  objective = "reg:squarederror")
    model <- xgb.dump(xgb, with_stats = T)
    importance_matrix <- xgb.importance(model = xgb)
    return(importance_matrix)
  }
 
  model1 = cv_xgboost(folds$Fold01,1)
  model2 = cv_xgboost(folds$Fold02,2)
  model3 = cv_xgboost(folds$Fold03,3)
  model4 = cv_xgboost(folds$Fold04,4)
  model5 = cv_xgboost(folds$Fold05,5)
  model6 = cv_xgboost(folds$Fold06,6)
  model7 = cv_xgboost(folds$Fold07,7)
  model8 = cv_xgboost(folds$Fold08,8)
  model9 = cv_xgboost(folds$Fold09,9)
  model10 = cv_xgboost(folds$Fold10,10)

  pdf('./figures/importance_BIS.pdf',width=20,height=12)
  par(mfrow=c(2,5))
  xgb.plot.importance(model1[1:20,])
  xgb.plot.importance(model2[1:20,])
  xgb.plot.importance(model3[1:20,])
  xgb.plot.importance(model4[1:20,])
  xgb.plot.importance(model5[1:20,])
  xgb.plot.importance(model6[1:20,])
  xgb.plot.importance(model7[1:20,])
  xgb.plot.importance(model8[1:20,])
  xgb.plot.importance(model9[1:20,])
  xgb.plot.importance(model10[1:20,])
  
  final_importance = merge(model1[,1:2],model2[,1:2],suffixes=c(".1",".2"),by="Feature")
  final_importance = merge(final_importance,model3[,1:2],suffixes=c(".1",".2"),by="Feature")
  final_importance = merge(final_importance,model4[,1:2],suffixes=c(".3",".4"),by="Feature")
  final_importance = merge(final_importance,model5[,1:2],suffixes=c(".5",".6"),by="Feature")
  final_importance = merge(final_importance,model6[,1:2],suffixes=c(".7",".8"),by="Feature")
  final_importance = merge(final_importance,model7[,1:2],suffixes=c(".9",".10"),by="Feature")
  final_importance = merge(final_importance,model8[,1:2],suffixes=c(".11",".12"),by="Feature")
  final_importance = merge(final_importance,model9[,1:2],suffixes=c(".13",".14"),by="Feature")
  final_importance = merge(final_importance,model10[,1:2],suffixes=c(".15",".26"),by="Feature")
 
  impt = final_importance
  impt$Gain = rowMeans(impt[ ,2:11], na.rm=TRUE)
  xgb.plot.importance(impt[,c(1,12)])
  scores = as.data.frame(impt[,c(1,12)])
  scores_order = scores[order(scores$Gain, decreasing = TRUE),]
  file_path = paste0("./result_xgboost/xgb_importance_BIS.csv")
  write.csv(scores_order,file = file_path, row.names = FALSE)
