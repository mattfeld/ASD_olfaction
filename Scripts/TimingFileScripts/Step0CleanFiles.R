#### Cleaning the raw timing ####
subj.raw <- t(read.xlsx("SubjectNames.xlsx",1))
subj.keep <- subj.raw[-grep("_",subj.raw)]

# 1. Move data to clean file

for(c in subj.keep){
  hold.data <- read.delim2(paste0("raw_timing/",c,".txt"), fileEncoding="UCS-2LE")
  new.name <- paste0("clean_timing/",c,".txt")
  write.table(hold.data,new.name,quote=F,col.names=T,row.names=F, fileEncoding="UCS-2LE",sep='\t')
}

# 2. Combine a and b parts, move to clean file
subj.a <- grep("_a",subj.raw)
subj.b <- grep("_b",subj.raw)

for(sab in 1:length(subj.a)){
  hold.a <- read.delim2(paste0("raw_timing/",subj.raw[subj.a[sab]],".txt"), fileEncoding="UCS-2LE")
  hold.b <- read.delim2(paste0("raw_timing/",subj.raw[subj.b[sab]],".txt"), fileEncoding="UCS-2LE")
  common.col <- intersect(names(hold.a),names(hold.b))
  col.ind.a <- col.ind.b <- rep(0,length(common.col))
  for(j in 1:length(common.col)){
    col.ind.a[j] <-which(names(hold.a)==common.col[j])
    col.ind.b[j] <-which(names(hold.b)==common.col[j])
  }
  comb.data <- rbind(hold.a[col.ind.a],hold.b[col.ind.b]) 
  comb.name <- paste0("clean_timing/",sub("_a","",subj.raw[subj.a[sab]]),".txt")
  write.table(comb.data,comb.name,quote=F,col.names=T,row.names = F, fileEncoding="UCS-2LE",sep='\t')
}

# 3. Clean the rest with underscores
# (there is a 698_test file that I am ignoring)
weird <- setdiff(grep("_weird",subj.raw),c(subj.a,subj.b))

for(j in 1:length(weird)){
  hold.data <- read.delim2(paste0("raw_timing/",subj.raw[weird[j]],".txt"), fileEncoding="UCS-2LE")
  if(length(grep("STRING",names(hold.data)))>0){
    hold.data <- as.data.frame(read.delim2(paste0("raw_timing/",subj.raw[weird[j]],".txt"), fileEncoding="UCS-2LE",skip=3))
  }
  new.name <- paste0("clean_timing/",sub("_weird","",subj.raw[weird[j]]),".txt")
  write.table(hold.data,new.name,quote=F,col.names=T,row.names=F, fileEncoding="UCS-2LE",sep='\t')

}









