## XGBoost
library(xgboost)
library(readr)
library(stringr)
library(caret)
library(car)
library(dplyr)
library(utils)
library(tidyverse)
library(ggplot2)
library(ggsci)
library(lme4)
library(lmerTest)
library(simr)
library(MuMIn)
library(caret)

runtimes = 1

## Helper function
## This function helps remove duplicates in the File 04 dataset
rm_dup4 = function(df){
  # remove duplicates
  rm_child = df %>% group_by(CandID,age) %>%
    summarise_at(vars(-c(`Project.Abbreviation`,
                         `Participant.ID`,
                         `Project.Name`,
                         `Gender`,
                         `batch`)), mean) %>% 
    ungroup()
  # reorder the data columns
  new_df = rm_child %>% select(3:(ncol(rm_child)-1),1,2,ncol(rm_child))
  return(new_df)
}

## function to summary the number of records and the number of unique IDs
row_id_num_summary = function(df) {
  cat(paste0("\nNumber of rows ", deparse(substitute(df)),": ", nrow(df)),"\n")
  cat(paste0("\nNumber of unique IDs ",deparse(substitute(df)),": ", length(unique(df$CandID))),"\n")
}

## Average the nutrients by weighting weekend and weekday data from the same week
week_weight = function(df) {
  ## Create new variable groupid to show the week index that the data is from
  df = df %>% group_by(CandID) %>% arrange(age) %>% mutate(diff_day = age - lag(age))
  df = df %>% mutate(weight=ifelse(weekend==0,5,2)) %>% arrange(CandID, age)
  groupid = rep(0,nrow(df))
  for (i in 1:nrow(df)) {
    if (is.na(df$diff_day[i])) {
      groupid[i] = 1
    } else {
      if (df$diff_day[i]<7){
        groupid[i] = groupid[i-1]
      } else{
        groupid[i] = groupid[i-1]+1
      }
    }
  }
  df$groupid = groupid
  ## average nutrient data from the same week index
  df = df %>% group_by(CandID,groupid,.add = TRUE) %>%
    summarise(across(Total.Grams:Gluten..g.,weighted.mean,weight),
              #across(FRU0100:GRS1300,weighted.mean,weight),
              age=last(age))
  df = df %>% select(Total.Grams:Gluten..g.,CandID,age,groupid)
  return(df)
}

match_mullen = function(df, colname){
  rows = nrow(df)
  
  ## Create "mullen" and "examiner" columns
  df$examiner = NA
  df[[colname]] = NA
  
  ## Match mullen score to each nutrient record and store it to mullen_score
  mullen_score = rep(NA,rows)
  examiner_info = rep(NA,rows)
  for (i in 1:rows) {
    merged = mullen[which((mullen$PID==df$CandID[i])),]
    if(nrow(merged)!=0){
      #print(i)
      age_id = which((merged$Age<=(df$age[i]+31))&
                       (merged$Age>=(df$age[i]-31)))
      if(length(age_id)==1) {
        #print(i)
        mullen_score[i]=as.numeric(merged[age_id,colname])
        examiner_info[i]=merged[age_id,]$Examiner
      } else if(length(age_id)>1){
        print(i)
        mullen_score[i]=as.numeric(merged[age_id[1],colname])
        examiner_info[i]=merged[age_id[1],]$Examiner
      }
    }
  }
  
  ## Use mullen_score to fill "mullen" column
  df[[colname]] = mullen_score
  df$examiner = examiner_info
  df$examiner = as.factor(df$examiner)
  
  ## Summarize the information of mullen score
  print(summary(mullen_score))
  print(table(df$examiner))
  
  return(df)
}

## Format Factor Variables
df_as_factor = function(df, avg) {
  df$Sex = as.factor(df$Sex)
  df$Delivery.Method = as.factor(df$Delivery.Method)
  df$Ethnicity = as.factor(df$Ethnicity)
  df$Race = as.factor(df$Race)
  df$Education.Level = as.factor(df$Education.Level)
  df$Education.Level1 = as.factor(df$Education.Level1)
  df$Household.Income=as.factor(df$Household.Income)
  df$CandID=as.factor(df$CandID)
  df$examiner=as.factor(df$examiner)
  if (avg) {
    df$groupid = as.factor(df$groupid)
  } else {
    df$weekend=as.factor(df$weekend)
  }
  return(df)
}

## This function change the factor levels, grouping some minority levels into one
change_fct_levels = function(df) {
  levels(df$Delivery.Method)[levels(
    df$Delivery.Method)!="Emergency C-Section"]="Not Emergency C-Section"
  levels(df$Education.Level)[
    levels(df$Education.Level)=="Graduate Degree"|
      levels(df$Education.Level)=="Some Graduate School"]=">grad"
  levels(df$Education.Level)[
    levels(df$Education.Level)!=">grad"]="<grad"
  levels(df$Education.Level1)[
    levels(df$Education.Level1)=="Graduate Degree"|
      levels(df$Education.Level1)=="Some Graduate School"]=">grad"
  levels(df$Education.Level1)[
    levels(df$Education.Level1)!=">grad"]="<grad"
  levels(df$Household.Income)[
    levels(df$Household.Income)=="$25,000 - $34,999"|
      levels(df$Household.Income)=="$35,000 - $49,999"|
      levels(df$Household.Income)=="$50,000 - $74,999"|
      levels(df$Household.Income)=="less than $24,999"]="<75k"
  levels(df$Household.Income)[
    levels(df$Household.Income)=="$75,000 - $99,999"|
      levels(df$Household.Income)=="$100,000 - $149,999"]="75k-150k"
  levels(df$Household.Income)[
    levels(df$Household.Income)=="$150,000 - $199,000"|
      levels(df$Household.Income)=="over $200,000"]=">150k"
  return(df)
}

## Load File 04 Data
file04 = read.csv("../total.csv")
## Filter out children between 18 to 24 years
file04 = file04[which(file04$age>18*30 & file04$age<=24*30),]
## Check the age range after filter
print(summary(file04$age))
## Summarize the Number of Records and CandIDs
row_id_num_summary(file04)

## Create `Weekend` Variable to indicate whether the day of intake is weekend
file04$weekend <- as.integer(ifelse(file04$Day.of.Intake==0 | file04$Day.of.Intake==6, 1, 0))
file04 = file04[,-c(4:5,7:17,132:142,151:163,179:182,216:225)]

## Remove duplicates within different batches
file04_rm = rm_dup4(file04)
row_id_num_summary(file04_rm)

colnames(file04)

file04_new = week_weight(file04_rm)
row_id_num_summary(file04_new)

## Read Mullen Score File
mullen = read.csv("../Cognitive/Mullen_Final.csv")

## Remove NAs in columns Age and Comp Score
mullen = na.omit(mullen,cols = c("Age","Comp"))

## Summarize the Number of Records
#View(mullen)
nrow(mullen)
length(unique(mullen$PID))

file04_total = match_mullen(file04_new, "Comp")

## Summarize number of rows and unique CandIDs
row_id_num_summary(file04_total)

## Remove NAs
cat("remove NAs")
file04_total_rmna = na.omit(file04_total)

## Summarize number of rows and unique CandIDs after removing NAs
row_id_num_summary(file04_total_rmna)
for (runtimes in 1:100) {
  set.seed(runtimes)
  train_id = sample(c(1:nrow(file04_total_rmna)), round(nrow(file04_total_rmna)*0.8,0), 
                    replace = FALSE)
  
  # one-hot-encoding categorical features
  # ohe_feats = c('CandID', 'groupid', 'examiner')
  # dummies <- dummyVars(~ CandID +  groupid + examiner, data = file04_total_rmna)
  # df_all_ohe <- as.data.frame(predict(dummies, newdata = file04_total_rmna))
  # df_all_combined <- cbind(file04_total_rmna[,-c(which(colnames(file04_total_rmna) %in% ohe_feats))],
  #                          df_all_ohe)
  
  df_all_combined = subset(file04_total_rmna, select = -c(Total.Grams, CandID, age, groupid, examiner, Comp))
  test_id_path = paste0("test_data/train_id", runtimes, ".csv")
  write.csv(train_id,file = test_id_path, row.names = FALSE)
  # X = subset(df_all_combined[train_id,], select = -c(Comp,age,Total.Grams))
  # X_test = subset(df_all_combined[-train_id,], select = -c(Comp,age,Total.Grams))
  X = df_all_combined[train_id,]
  X_test = df_all_combined[-train_id,]
  Y = file04_total_rmna[train_id,"Comp"]$Comp
  ncol(X)
  
  ## Tuning Hyperparameters
  ### Create 10 Folds
  folds = createFolds(file04_total_rmna[train_id,]$Comp, k=10)
  
  ### The function that returns the model evaluation metric we want to optimize
  scoringfunction = function(eta, max_depth, min_child_weight, subsample,alpha) {
    #### Set Hyperparameters
    pars <- list( 
      booster = "gbtree",
      eta = eta,
      max_depth = max_depth,
      min_child_weight = min_child_weight,
      subsample = subsample,
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
      nround = 1000,
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
    max_depth = c(2L, 14L),
    min_child_weight = c(1,25),
    subsample = c(0.25, 1),
    alpha = c(0.1,10)
  )
  
  optObj <- bayesOpt(
    FUN = scoringfunction,
    bounds = bounds,
    initPoints = 10,
    iters.n = 80
  )
  
  cv_xgboost = function(x,i) {
    training_fold = X[-x, ]
    test_fold = X[x, ]
    xgb = xgboost(data = as.matrix(training_fold), label = Y[-x],
                  eta = bestpars$eta,max_depth = bestpars$max_depth, 
                  nround=num_round, 
                  subsample = bestpars$subsample,
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
  #impt = read.csv(file = "final_improtant.csv")
  impt = final_importance
  impt$Gain = rowMeans(impt[ ,2:11], na.rm=TRUE)
  xgb.plot.importance(impt[,c(1,12)])
  scores = as.data.frame(impt[,c(1,12)])
  scores_order = scores[order(scores$Gain, decreasing = TRUE),]
  file_path = paste0("new_xgb_importance/round",runtimes,".csv")
  write.csv(scores_order,file = file_path, row.names = FALSE)
}
