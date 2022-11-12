library(httr)
library(data.table)
library(Rtsne)
library(ggplot2)

set.seed(3)


getEmbeddings<-function(text){
input <- list(
  instances =list( text)
)
res <- POST("https://dsalpha.vmhost.psu.edu/api/use/v1/models/use:predict", body = input,encode = "json", verbose())
emb<-unlist(content(res)$predictions)
emb
}



train_emb<-fread('./project/volume/data/raw/training_emb.csv')
train_text<-fread('./project/volume/data/raw/training_data.csv')
test_emb<-fread('./project/volume/data/raw/test_emb.csv')
test_text<-fread('./project/volume/data/raw/test_file.csv', header = TRUE, fill = TRUE)
example<-fread('./project/volume/data/raw/examp_sub.csv')
train_text$id <- 1:250

emb_dt<-NULL
as.data.frame.table(emb_dt)

for (i in 1:length(data$text)){
  emb_dt<-rbind(emb_dt,getEmbeddings(data$text[i]))
  
}
emb_dt<-data.table(emb_dt)

tsne<-Rtsne(emb_dt,perplexity=10)

tsne_dt<-data.table(tsne$Y)

tsne_dt$pet<-data$Pet
tsne_dt$id<-data$PSU_access_id 

ggplot(tsne_dt,aes(x=V1,y=V2,col=pet,label=id))+geom_text()

# -------------------My Code----------------------------
tsne_train<-Rtsne(train_emb,perplexity=20)
tsne_train_dt<-data.table(tsne_train$Y)
tsne_train_dt$reddit<-train_text$reddit
tsne_train_dt$id<-train_text$id 

ggplot(tsne_train_dt,aes(x=V1,y=V2,col=reddit,label=id))+geom_text()
