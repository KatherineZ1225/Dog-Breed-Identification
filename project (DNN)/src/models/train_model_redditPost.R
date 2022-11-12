library(httr)
library(data.table)
library(Rtsne)
library(ggplot2)
library(caret)
library(ClusterR)
library(xgboost)

set.seed(3)

train<-fread('./project/volume/data/interim/train.csv')
test<-fread('./project/volume/data/interim/test.csv')
master<-fread('./project/volume/data/interim/master.csv')
train_text<-fread('./project/volume/data/raw/training_data.csv')
example<-fread('./project/volume/data/raw/examp_sub.csv')
nine<-fread('./project/volume/data/interim/9col.csv')
xyh<-fread('./project/volume/data/processed/fileout.csv')
xyh$id<-1:24750
fwrite(xyh,'./project/volume/data/processed/fileout.csv')

# ----------------------------------Null Model----------------------------------

null_m<-train_text[,.N, by = reddit]
null_m$N<-null_m$N/sum(null_m$N)
null_m$reddit<-paste0("reddit",null_m$reddit)
melt_example<-melt(example, id.vars ="id", variable.name = "reddit")
setkey(null_m, reddit)
setkey(melt_example, reddit)
null_m<-merge(melt_example, null_m)
null_m$value<-NULL
null_m<-dcast(null_m,id~reddit, value.var = "N")
fwrite(null_m, './project/volume/data/processed/null_model.csv')


#-------------------------------Make xgboost model------------------------------

train_tsne<-tsne_dt[!reddit == 20,]
test_tsne<-tsne_dt[reddit == 20,]
id_train<-train_tsne$id
id_test<-test_tsne$id

y.train<-train_tsne$reddit
train_tsne$id<-NULL
test_tsne$id<-NULL

# work with dummies

dummies <- dummyVars(reddit~ ., data = train_tsne)
x.train<-predict(dummies, newdata = train_tsne)
x.test<-predict(dummies, newdata = test_tsne)

# notice that I've removed label=departure delay in the dtest line, I have departure delay available to me with the in my dataset but
# you dont have price for the house prices.
dtrain <- xgb.DMatrix(x.train,label=y.train,missing=NA)
dtest <- xgb.DMatrix(x.test,missing=NA)

hyper_perm_tune<-NULL
########################
# Use cross validation #
########################

param <- list(  objective           = "multi:softprob",
                gamma               = 0.02,
                booster             = "gbtree",
                eval_metric         = "mlogloss",
                eta                 = 0.02,
                max_depth           = 8,
                min_child_weight    = 1,
                subsample           = 0.54, #start from 1
                colsample_bytree    = 0.9,
                tree_method = 'hist',
                num_class = 11
                # n_estimators=10,  fot gbliner booster
                # learning_rate=0.001
)


XGBm<-xgb.cv( params=param,nfold=10,nrounds=10000,missing=NA,data=dtrain,print_every_n=100,early_stopping_rounds=25, verbose = 1)

best_ntrees<-unclass(XGBm)$best_iteration

new_row<-data.table(t(param))

new_row$best_ntrees<-best_ntrees

test_error<-unclass(XGBm)$evaluation_log[best_ntrees,]$test_mlogloss_mean
new_row$test_error<-test_error
hyper_perm_tune<-rbind(new_row,hyper_perm_tune)

####################################
# fit the model to all of the data #
####################################

watchlist <- list( train = dtrain)

# now fit the full model
XGBm<-xgb.train( params=param,nrounds=best_ntrees,missing=NA,data=dtrain,watchlist=watchlist,print_every_n=1)

# get predictions from the model object
pred<-predict(XGBm, newdata = dtest)

# format the predictions to add them to the submission file
results<-data.table(matrix(pred,ncol=11,byrow=T))

# add to the submission file

example$redditCFB<-results$V1
example$redditCooking<-results$V2
example$redditMachineLearning<-results$V3
example$redditRealEstate<-results$V4
example$redditStockMarket<-results$V5
example$redditcars<-results$V6
example$redditmagicTCG<-results$V7
example$redditpolitics<-results$V8
example$redditscience<-results$V9
example$reddittravel<-results$V10
example$redditvideogames<-results$V11

fwrite(example,'./project/volume/data/processed/submission.csv' )
