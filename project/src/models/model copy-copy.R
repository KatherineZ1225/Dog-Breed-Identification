
library(data.table)
library(Rtsne)
library(ggplot2)
library(caret)
library(ggplot2)
library(ClusterR)
set.seed(8)

# load in data 
data<-fread("./project/volume/data/raw/data.csv")
example<-fread("./project/volume/data/raw/example_sub.csv")

data$id = NULL

# do a pca
pca<-prcomp(data)

# look at the percent variance explained by each pca
screeplot(pca)

# look at the rotation of the variables on the PCs
pca

# see the values of the scree plot in a table 
summary(pca)

# see a biplot of the first 2 PCs
biplot(pca)

# use the unclass() function to get the data in PCA space
pca_dt<-data.table(unclass(pca)$x)



# run t-sne on the PCAs, note that if you already have PCAs you need to set pca=F or it will run a pca again. 
# pca is built into Rtsne, ive run it seperatly for you to see the internal steps

tsne<-Rtsne(pca_dt,pca = F,perplexity=30,check_duplicates = F,normalize= T, initial_dims = 100)

# grab out the coordinates
tsne_dt<-data.table(tsne$Y)


# use a gaussian mixture model to find optimal k and then get probability of membership for each row to each group

# this fits a gmm to the data for all k=1 to k= max_clusters, we then look for a major change in likelihood between k values
k_bic<-Optimal_Clusters_GMM(tsne_dt[,.(V1,V2)],max_clusters = 10,criterion = "BIC")

# now we will look at the change in model fit between successive k values
delta_k<-c(NA,k_bic[-1] - k_bic[-length(k_bic)])

opt_k<-4

# now we run the model with our chosen k value
gmm_data<-GMM(tsne_dt[,.(V1,V2)],opt_k)

# the model gives a log-likelihood for each datapoint's membership to each cluster, me need to convert this 
# log-likelihood into a probability

l_clust<-gmm_data$Log_likelihood^10

l_clust<-data.table(l_clust)

net_lh<-apply(l_clust,1,FUN=function(x){sum(1/x)})

cluster_prob<-1/l_clust/net_lh

example$breed_1<-cluster_prob$V1
example$breed_2<-cluster_prob$V2
example$breed_3<-cluster_prob$V4
example$breed_4<-cluster_prob$V3

fwrite(example,"./project/volume/data/processed/null_model_12_set1.csv")
dd<-fread("./project/volume/data/processed/null_model_7_65.csv")

