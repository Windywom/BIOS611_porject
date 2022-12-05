from xgboost import XGBRegressor as XGBR
from sklearn.ensemble import RandomForestRegressor as RFR
from sklearn.linear_model import LinearRegression as LinearR
from sklearn.model_selection import KFold, cross_val_score as CVS, train_test_split as TTS
from sklearn.metrics import mean_squared_error as MSE
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

FA = pd.read_excel('./source_data_DTI/DTI_FA.xlsx')
Behav=pd.read_excel('./source_data_DTI/xingweiliaobiao.xlsx')

X=FA.iloc[:, 3:]
y=Behav.iloc[:, 6]

reg = XGBR(n_estimators=100).fit(X,y) #training
feature_impor=reg.feature_importances_ #check the importance of feature
feature_impor.to_csv("./results/important_feature_py.csv", index=False);

reg = XGBR(n_estimators=100) #xgboost modeling
rsqure=[];
score=CVS(reg,X,y,cv=5).mean() # 5-fold cross validation r squre
rsqure.append(score)

nmsq=[]
score=CVS(reg,X,y,cv=5,scoring='neg_mean_squared_error').mean() # calculate neg_mean_squared_error
nmsq.append(score)
nmsq

#comapre with random forest and linear regression 
rfr = RFR(n_estimators=100) # random forest modeling
score=CVS(rfr,X,y,cv=10).mean()  
rsqure.append(score)
score=CVS(rfr,X,y,cv=10,scoring='neg_mean_squared_error').mean()
nmsq.append(score)

lr = LinearR()   #linear regression modeling
score=CVS(lr,X,y,cv=10).mean()
rsqure.append(score)
score=CVS(lr,X,y,cv=10,scoring='neg_mean_squared_error').mean()
nmsq.append(score)

rsqure.to_csv("./results/rsqure.csv", index=False);
nmsq.to_csv("./results/neg_mean_squared_error.csv", index=False);

##Tuning parameters
reg = XGBR(n_estimators=10,silent=True)
CVS(reg,Xtrain,Ytrain,cv=5,scoring='neg_mean_squared_error').mean()

