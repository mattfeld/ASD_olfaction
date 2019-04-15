
library(tiff)
library(ghostscript)
library(reshape2)
library(ez)


### Set parameters
dataDir <- "/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/ppiAnalysis/stats_out/"
outDir <- dataDir



### Functions

GraphNames1.Function <- function(string, q){
  
  # who cares about efficiency? just condition the hell out of it
  if(q == "FBO_LPF"){
    if(string=="mask_1"){return("FBO: L. Piriform -> R. Occipital")}
  }else if(q == "FBO_REC"){
    if(string=="mask_1"){return("FBO: R. Entorhinal -> Brain Stem")}
  }else if(q == "UBO_LPF"){
    if(string=="mask_1"){return("UBO: L. Piriform -> R. D. Parietal")}
  }else if(q == "UBO_REC"){
    if(string=="mask_1"){return("UBO: R. Entorhinal -> R. Intrparietal Sulcus")}
    else if(string=="mask_2"){return("UBO: R. Entorhinal -> L. A. Cingulate")}
    else if(string=="mask_3"){return("UBO: R. Entorhinal -> L. S. Frontal Sulcus")}
    else if(string=="mask_4"){return("UBO: R. Entorhinal -> L. M. S. Frontal Sulcus")}
    else if(string=="mask_5"){return("UBO: R. Entorhinal -> Cerebellum")}
  }
}

GraphNames2.Function <- function(string, q){
  
  if(q == "FBO_LPF"){
    if(string=="mask_1"){return("ROcc")}
  }else if(q == "FBO_REC"){
    if(string=="mask_1"){return("BS")}
  }else if(q == "UBO_LPF"){
    if(string=="mask_1"){return("rdPar")}
  }else if(q == "UBO_REC"){
    if(string=="mask_1"){return("rIPS")}
    else if(string=="mask_2"){return("lACC")}
    else if(string=="mask_3"){return("lSFS")}
    else if(string=="mask_4"){return("lmSFG")}
    else if(string=="mask_5"){return("Cer")}
  }
}

SE.Function <- function(x,plot_data){
  SE <- matrix(0,nrow=1,ncol=x)
  for(a in 1:x){
    SE[,a] <- sd(plot_data[,a])/sqrt(length(plot_data[,a]))
  }
  # SE <- sd(plot_data[,x])/sqrt(length(plot_data[,x]))     # SE
  return(SE)
}


DF <- hold.df
maskN <- mask.name
type.h <- j

Graph.Function <- function(DF,maskN,type.h){
  
  ind.C <- grep("C", DF[,1])
  ind.A <- grep("A", DF[,1])
  
  x.C <- mean(DF[ind.C,2])
  x.A <- mean(DF[ind.A,2])
  MEANS <- c(x.C, x.A)
  
  e.C <- sd(DF[ind.C,2])/sqrt(length(ind.C))
  e.A <- sd(DF[ind.A,2])/sqrt(length(ind.A))
  E.BARS <- c(e.C, e.A)
  
  # NAME <- GraphNames2.Function(maskN,type.h)
  # TITLE <- GraphNames1.Function(maskN,type.h)
  TITLE <- "Seed - Precentral Sulcus Connectivity"
  RANGE <- range(c(MEANS,((MEANS-E.BARS)-(E.BARS)),((MEANS+E.BARS)+(E.BARS)),0))
  # RANGE <- c(min(DF[,2]),max(DF[,2]))
  XNAMES <- c("Control","Autistic")
  
  plotable <- matrix(0,nrow=2,ncol=2)
  plotable[1,] <- MEANS
  plotable[2,] <- E.BARS

  # graphOut <- paste0(outDir,"Fig_",type.h,"_",NAME,".tiff")
  graphOut <- paste0(outDir,"Fig_FBO_RAWM_PCS.tiff")
  bitmap(graphOut, width = 6.5, units = 'in', type="tiff24nc", res=1200)
  barCenters <- barplot(plotable[1,], names.arg = XNAMES, main=TITLE, ylab="Beta Coef.",ylim=RANGE)
  segments(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS)
  arrows(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS, lwd = 1, angle = 90, code = 3, length = 0.05)
  text(barCenters[1]+0.6,RANGE[2]-2,"*",cex=3)
  dev.off()
}



### Do it
j <- "TTEST_FBO_RAWM_mask_1_betas"

# for(j in c("FBO_LPF", "FBO_REC", "UBO_LPF", "UBO_REC")){
for(j in TTEST_FBO_RAWM_mask_1_betas){
  
  ### get info
  # df.raw <- read.delim(paste0(dataDir, "Master_",j,".txt"),header=F)
  df.raw <- read.delim(paste0(dataDir,j,".txt"),header=F)
  
  #mask
  # ind.mask <- grep("mask", df.raw[,1])
  # num.mask <- length(ind.mask)
  num.mask <- 1
  
  #subjects
  ind.subj <- grep("File", df.raw[,1])
  len.subj <- length(ind.subj)
  num.subj <- len.subj/num.mask
  
  
  #### Do analyses on Inter Coef from TTESTS
  #inter
  ind.inter <- grep("Int", df.raw[,2])
  len.inter <- length(ind.inter)
  num.inter <- (len.inter/num.mask)/num.subj
  
  # organize dataframe
  h.data <- matrix(as.numeric(as.character(df.raw[grep("Int",df.raw[,2]),3])),ncol=num.inter,byrow=T)
  Ndata <- matrix(0,nrow=num.subj, ncol=num.mask*num.inter+1)
  for(i in 1:num.mask){
    Ndata[,(num.inter*i-(num.inter-1)):(num.inter*i)] <- h.data[(num.subj*i-(num.subj-1)):(num.subj*i),1:num.inter]
  }
  
  # add group info
  for(i in 1:num.subj){
    if(length(grep("BO1",df.raw[ind.subj[i],1]))>0){
      Ndata[i,dim(Ndata)[2]] <- "C"
    }else{
      Ndata[i,dim(Ndata)[2]] <- "A"
    }
  }
  # colnames(Ndata) <- c(as.character(rep(df.raw[ind.mask,1],each=num.inter)),"Group")
  colnames(Ndata) <- c("Precentral Sulcus","Group")
  
  
  ### Run TTests
  
  c<-1; cc<-2
  hold.T <- list()

  for(i in 1:num.mask){

    hold.df <- as.data.frame(matrix(NA,nrow=dim(Ndata)[1],ncol=2))
    hold.df[,1] <- Ndata[,dim(Ndata)[2]]
    hold.df[,2] <- as.numeric(Ndata[,i])

    ind.A <- grep("A", hold.df[,1])
    ind.C <- grep("C", hold.df[,1])

    # hold.T[[c]] <- c("ROI", GraphNames2.Function(colnames(Ndata)[i],j))
    hold.T[[c]] <- "Precentral Sulcus"
    hold.T[[cc]] <- t.test(hold.df[ind.C,2],hold.df[ind.A,2],paired=F)

    c<-cc+1; cc<-cc+2
  }
  out.T <- capture.output(print(hold.T))
  # writeLines(out.T,paste0(outDir,"Master_TTest_",j,".txt"))
  writeLines(out.T,paste0(outDir,"TTEST.txt"))

  
  ### Graphs
  for(i in 1:num.mask){

    hold.df <- as.data.frame(matrix(NA, nrow=dim(Ndata)[1], ncol=2))
    hold.df[,1] <- Ndata[,dim(Ndata)[2]]
    hold.df[,2] <- as.numeric(Ndata[,i])
    
    colnames(hold.df) <- c("Group", "Inter")
    mask.name <- colnames(Ndata)[i]

    Graph.Function(hold.df,mask.name,j)
  }
}






### Extra code
##############


# #### Do analyses on betas
# #betas
# ind.betas <- grep("Co", df.raw[,2])
# len.betas <- length(ind.betas)
# num.betas <- (len.betas/num.mask)/num.subj
# 
# 
# ### organize dataframe
# ind.data <- matrix(as.numeric(as.character(df.raw[grep("Co",df.raw[,2]),3])),ncol=num.betas,byrow=T)
# Mdata <- matrix(0,nrow=num.subj, ncol=num.mask*num.betas+1)
# for(i in 1:num.mask){
#   Mdata[,(num.betas*i-(num.betas-1)):(num.betas*i)] <- ind.data[(num.subj*i-(num.subj-1)):(num.subj*i),1:num.betas]
# }
# 
# # add group info
# for(i in 1:num.subj){
#   if(length(grep("BO1",df.raw[ind.subj[i],1]))>0){
#     Mdata[i,dim(Mdata)[2]] <- "C"
#   }else{
#     Mdata[i,dim(Mdata)[2]] <- "A"
#   }
# }
# colnames(Mdata) <- c(as.character(rep(df.raw[ind.mask,1],each=num.betas)),"Group")
# 
# 
# ### Stats
# # WBRM on each cluster
# hold.WBRM <- list()
# 
# c<-1; cc<-2
# for(i in 1:num.mask){
# 
#   hold.df <- matrix(NA, nrow=dim(Mdata)[1], ncol=3)
#   hold.df[,1:2] <- Mdata[,c:cc]
#   hold.df[,3] <- Mdata[,dim(Mdata)[2]]
# 
#   data.long <- LWC.Function(dim(hold.df)[1],hold.df)
#   hold.WBRM[[c]] <- colnames(Mdata)[c]
#   hold.WBRM[[cc]] <- ezANOVA(data.long,dv=Value,wid=Subj,within=Stim,between=Group,type='III')
#   c<-cc+1; cc<-cc+2
# }
# out.WBRM <- capture.output(print(hold.WBRM))
# writeLines(out.WBRM,paste0(outDir,"Master_WBRM_",j,".txt"))
# 
# 
# 
# # PostHoc Ts
# hold.PHT <- list()
# 
# c<-1; cc<-2
# for(i in 1:num.mask){
# 
#   hold.df <- as.data.frame(matrix(NA, nrow=dim(Mdata)[1], ncol=3))
#   hold.df[,1] <- df.demo[,2]
#   hold.df[,2:3] <- Mdata[,c:cc]
# 
#   ind.S <- grep("S", hold.df[,1])
#   ind.A <- grep("A", hold.df[,1])
# 
#   ## 2 = D, 3 = N
#   h.out <- list()
#   h.out[[1]] <- "Comp: SDvSN"
#   h.out[[2]] <- t.test(hold.df[ind.S,2],hold.df[ind.S,3],paired=T)
#   h.out[[3]] <- "Comp: SDvAD"
#   h.out[[4]] <- t.test(hold.df[ind.S,2],hold.df[ind.A,2],paired=F)
#   h.out[[5]] <- "Comp: SDvAN"
#   h.out[[6]] <- t.test(hold.df[ind.S,2],hold.df[ind.A,3],paired=F)
#   h.out[[7]] <- "Comp: SNvAD"
#   h.out[[8]] <- t.test(hold.df[ind.S,3],hold.df[ind.A,2],paired=F)
#   h.out[[9]] <- "Comp: SNvAN"
#   h.out[[10]] <- t.test(hold.df[ind.S,3],hold.df[ind.A,3],paired=F)
#   h.out[[11]] <- "Comp: ADvAN"
#   h.out[[12]] <- t.test(hold.df[ind.A,2],hold.df[ind.A,3],paired=T)
# 
#   mask <- GraphNames.Function(colnames(Mdata)[c],j)
#   hold.PHT[[c]] <- c("Mask", mask)
#   hold.PHT[[cc]] <- h.out
#   c<-cc+1; cc<-cc+2
# }
# out.PHT <- capture.output(print(hold.PHT))
# writeLines(out.PHT,paste0(outDir,"Master_PostT_",j,".txt"))





# # PostHoc Ts
# hold.PHT <- list()
# 
# c<-1; cc<-2
# for(i in 1:num.mask){
#   
#   hold.df <- as.data.frame(matrix(NA, nrow=dim(Mdata)[1], ncol=3))
#   hold.df[,1] <- df.demo[,2]
#   hold.df[,2:3] <- Mdata[,c:cc]
#   
#   ind.S <- grep("S", hold.df[,1])
#   ind.A <- grep("A", hold.df[,1])
#   
#   ## 2 = D, 3 = N
#   h.out <- list()
#   h.out[[1]] <- "Comp: SDvSN"
#   h.out[[2]] <- t.test(hold.df[ind.S,2],hold.df[ind.S,3],paired=T)
#   h.out[[3]] <- "Comp: SDvAD"
#   h.out[[4]] <- t.test(hold.df[ind.S,2],hold.df[ind.A,2],paired=F)
#   h.out[[5]] <- "Comp: SDvAN"
#   h.out[[6]] <- t.test(hold.df[ind.S,2],hold.df[ind.A,3],paired=F)
#   h.out[[7]] <- "Comp: SNvAD"
#   h.out[[8]] <- t.test(hold.df[ind.S,3],hold.df[ind.A,2],paired=F)
#   h.out[[9]] <- "Comp: SNvAN"
#   h.out[[10]] <- t.test(hold.df[ind.S,3],hold.df[ind.A,3],paired=F)
#   h.out[[11]] <- "Comp: ADvAN"
#   h.out[[12]] <- t.test(hold.df[ind.A,2],hold.df[ind.A,3],paired=T)
#   
#   mask <- GraphNames.Function(colnames(Mdata)[c],j)
#   hold.PHT[[c]] <- c("Mask", mask)
#   hold.PHT[[cc]] <- h.out
#   c<-cc+1; cc<-cc+2
# }
# out.PHT <- capture.output(print(hold.PHT))
# writeLines(out.PHT,paste0(outDir,"Master_PostT_",j,".txt"))
