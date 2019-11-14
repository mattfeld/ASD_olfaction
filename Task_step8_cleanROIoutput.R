



### Set up orienting variables
workDir<-"/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/roiAnalysis/sub_betas/"
masterList <- read.delim(paste0(workDir,"Master_list.txt"))


### Function for extracting every n value of vector following position x
#
# This was needed because various comparisons will have a different
# number of betas, so the dataframe will have different dimensions
# and we will want to extract differing positions of the beta index.

splitVector.Function <- function(vector, startPosition, increase){
  vector[seq(startPosition,length(vector),increase)]
}


### Make output table
#
# Read in raw data, determine mask, number of betas, subjects,
# and then make the output table.
# Name columns according to raw data input.

for(i in t(masterList)){
  
  # load raw output
  dataRaw <- as.data.frame(read.delim(paste0(workDir,i),header = F))
  
  # detemine mask
  hold.mask <- gsub("^Betas_","",i)
  mask <- gsub("_sub.txt$","",hold.mask)

  # determine subjects
  ind.subj <- grep("File",dataRaw[,1])
  hold.subj <- as.character(dataRaw[ind.subj,1])
  list.subj <- gsub(" File","",hold.subj)
  
  # determine betas
  ind.beta <- grep("+tlrc",dataRaw[,1])
  num.beta <- length(ind.beta)/length(ind.subj)
  
  # names of betas
  ind.beta.start <- ind.beta[1]; ind.beta.end <- ind.beta[num.beta]
  hold.beta <- as.character(dataRaw[ind.beta.start:ind.beta.end,2])
  hold.beta.name1 <- gsub("\\#.*$","",hold.beta)
  name.beta <- gsub("^.*_","",hold.beta.name1)
  
  
  ## make output dataframe
  df.output <- matrix(0,nrow=length(ind.subj),ncol=1+num.beta)
  colnames(df.output) <- c("Subject",name.beta)
  df.output[,1] <- list.subj
  
  for(j in 1:num.beta){
    df.output[,j+1] <- as.numeric(as.character(dataRaw[(splitVector.Function(ind.beta,j,num.beta)),3]))
  }
  
  write.table(df.output,file=paste0(workDir,"Table_",mask,".txt"),sep = "\t",row.names=F,col.names=T,quote=F)
}
