library(httr)
library(data.table)
library(Rtsne)
library(ggplot2)
library(caret)
library(ClusterR)
library(xgboost)

set.seed(3)
# -----------------------1. Read Data-------------------------------------------
train_emb<-fread('./project/volume/data/raw/training_emb.csv')
train_text<-fread('./project/volume/data/raw/training_data.csv')
test_emb<-fread('./project/volume/data/raw/test_emb.csv')
test_text<-fread('./project/volume/data/raw/test_file.csv')


# -----------------------2. Label reddit & make train---------------------------
train_DT<-dcast(train_text,id~reddit,value.var="reddit")

train_DT$CFB[!is.na(train_DT$CFB)]<-1
train_DT$Cooking[!is.na(train_DT$Cooking)]<-1
train_DT$MachineLearning[!is.na(train_DT$MachineLearning)]<-1
train_DT$RealEstate[!is.na(train_DT$RealEstate)]<-1
train_DT$StockMarket[!is.na(train_DT$StockMarket)]<-1
train_DT$cars[!is.na(train_DT$cars)]<-1
train_DT$magicTCG[!is.na(train_DT$magicTCG)]<-1
train_DT$politics[!is.na(train_DT$politics)]<-1
train_DT$science[!is.na(train_DT$science)]<-1
train_DT$travel[!is.na(train_DT$travel)]<-1
train_DT$videogames[!is.na(train_DT$videogames)]<-1
train_DT[is.na(train_DT)]<-0

# transform format:

melt_DT<-melt(train_DT,id=c("id"),variable.name = "reddit")
melt_DT<-melt_DT[value==1][order(id)][,.(id,reddit)]
melt_DT$reddit<-as.integer(melt_DT$reddit)-1

melt_DT$train<-0
train<-cbind(melt_DT, train_emb)


# -----------------------3. make master-----------------------------------------
test_text$id<-1:nrow(test_text)
test_text$reddit<-20
test_text$train<-1
test<-cbind(test_text, test_emb)
test$text<-NULL

master<-rbind(train,test)
fwrite(master, './project/volume/data/interim/master.csv')
train$train<-NULL
test$train<-NULL
fwrite(train, './project/volume/data/interim/train.csv')
fwrite(test, './project/volume/data/interim/test.csv')


# -------------------------------4.do PCA on master-----------------------------
id<-master$id
reddit<-master$reddit
train_test<-master$train
master$id<-NULL
master$reddit<-NULL
master$train<-NULL

# do a pca
pca<-prcomp(master)
pca <- prcomp(master, center = TRUE, scale = TRUE)

# look at the percent variance explained by each pca
screeplot(pca)

# see the values of the scree plot in a table 
summary(pca)

# use the unclass() function to get the data in PCA space
pca_dt<-data.table(unclass(pca)$x)

# add back the party to prove to ourselves that this works
pca_dt$reddit<-reddit
train_pca<-pca_dt[!reddit == 20,]
# see a plot with the party data 
ggplot(pca_dt[!reddit == 20,],aes(x=PC1,y=PC2,col=reddit))+geom_point()

fwrite(pca_dt, './project/volume/data/interim/pca_dt.csv')


# ------------------------5. do tsne on pca result------------------------------

# run t-sne on the PCAs, note that if you already have PCAs you need to set pca=F or it will run a pca again. 
# pca is built into Rtsne, ive run it seperatly for you to see the internal steps

# tsne<-Rtsne(pca_dt[,1:512], pca = F,perplexity=20,check_duplicates = F)
# tsne<-Rtsne(pca_dt[,1:512], pca = F,perplexity=50,check_duplicates = F) #1210_2
# tsne<-Rtsne(pca_dt[,1:512], pca = F,perplexity=100,check_duplicates = F) #1210_3
# tsne<-Rtsne(pca_dt[,1:512], pca = F,perplexity=250,check_duplicates = F) #1210_4
# tsne<-Rtsne(pca_dt[,1:512], pca = F,perplexity=300,check_duplicates = F) #1210_5
# tsne<-Rtsne(pca_dt[,1:512], pca = F,perplexity=1000,check_duplicates = F) #1210_6
tsne<-Rtsne(pca_dt[,1:512], pca = F,perplexity=5000,check_duplicates = F) #1210_6
# tsne <- Rtsne(pca_dt[,1:7], dim = 3, perplexity = 30, pca = FALSE, max_iter = 50,check_duplicates=F)
# tsne<-Rtsne(pca_dt[,1:7], pca = F,perplexity=300,check_duplicates = F) #1210_5

# grab out the coordinates
tsne_dt<-data.table(tsne$Y)

# add back in party and cats so we can see what the analysis did with them
tsne_dt$reddit<-reddit
tsne_dt$id<-id
ggplot(tsne_dt[!reddit == 20,],aes(x=V1,y=V2,col=reddit,label=id))+geom_text()
ggplot(tsne_dt,aes(x=V1,y=V2,col=reddit))+geom_point()

fwrite(tsne_dt, './project/volume/data/interim/tsne_dt.csv')
