
library(openxlsx)
subj.txt <- t(read.xlsx("SubjectNames.xlsx",2))
subj <- sub(".txt","",subj.txt)
N <- length(subj)

for(s in subj){
  hold.data <- read.delim2(paste0("clean_timing/",s,".txt"), fileEncoding="UCS-2LE")
  
  ## Including only Odor Blocks
  red.data <- hold.data[hold.data$Running!="AFC1",]
  n.trials <- dim(red.data)[1]
  
  ## Creating first timing files
  labelT <- data.frame(matrix(0,nrow=n.trials*8,ncol=2))
  TIMING <- NULL
  for(i in 1:n.trials){
    labelT[(8*i-7),] <- c(as.character(red.data$ITI1.OnsetToOnsetTime)[i],"ITI1")
    labelT[(8*i-6),] <- c(as.character(red.data$FixBlack1.OnsetToOnsetTime)[i],"FixB1")
    labelT[(8*i-5),] <- c(as.character(red.data$FixBlack2.OnsetToOnsetTime)[i],"FixB2")
    labelT[(8*i-4),] <- c(as.character(red.data$FixGreen1.OnsetToOnsetTime)[i],"FixG")
    labelT[(8*i-3),] <- c(as.character(red.data$ITI2.OnsetToOnsetTime)[i],"ITI2")
    labelT[(8*i-2),] <- c(6000,"Response1")
    labelT[(8*i-1),] <- c(as.character(red.data$Blank.OnsetToOnsetTime)[i],"Blank")
    labelT[(8*i),] <- c(6000,"Response2")
    
    
    length.label <- round(as.numeric(labelT[(8*i-7):(8*i),1])/100) # timings in 500 ms
    # expanding the names to matach the 500 ms intervals
    expanding <- rep(c("ITI1","Baseline","FixB2","FixG","ITI2","Response1","Baseline","Response2"),length.label)
    ### Populating up the Timing Files per trial
    timing.hold <- matrix(0,nrow=length(expanding),ncol=3)
    timing.hold[which(expanding=="Baseline"),1] <- 1
    timing.hold[which(expanding=="Response1"),2] <- 1
    timing.hold[which(expanding=="Response2"),3] <- 1
    TIMING <- rbind(TIMING,timing.hold) # subject timing files
  }
  
  write.table(TIMING,paste0("TimingFiles/",s,"_TF.txt"),quote=F,col.names=F,row.names = F)
  
  ####### Variable Timing Files #######
  
  for(b in c("OdorBlock1","OdorBlock2","OdorBlock3")){
    start.time <- min(as.numeric(as.character(red.data$ITI1.OnsetTime[red.data$Running==b])))/1000   # relative start time
    ind.b <- red.data$Running==b
    ## For ITI1
    rel.onsetJ <-as.numeric(as.character(red.data$ITI1.OnsetTime[ind.b]))/1000-start.time  
    durationJ <- as.numeric(as.character(red.data$ITI1.OnsetToOnsetTime[ind.b]))/1000  
    timing.J1 <- paste0(round(rel.onsetJ,1),":",round(durationJ,1))
    write.table(t(timing.J1),file=paste0("TimingFiles/",s,"_Jit1.txt"),append=ifelse(b=="OdorBlock1",FALSE,TRUE),quote=F,col.names=F,row.names=F)
    
    rel.onset2 <- as.numeric(as.character(red.data$FixBlack2.OnsetTime[ind.b]))/1000-start.time  
    duration2 <- as.numeric(as.character(red.data$FixBlack2.OnsetToOnsetTime[ind.b]))/1000+as.numeric(as.character(red.data$ITI2.OnsetToOnsetTime))[ind.b]/1000+as.numeric(as.character(red.data$FixGreen1.OnsetToOnsetTime[ind.b]))/1000
    timing2 <- paste0(round(rel.onset2,1),":",round(duration2,1))
    
    ## For Familiar
    indF <- red.data$Odor[red.data$Running==b]=="FBO"
    write.table(t(timing2[indF]),file=paste0("TimingFiles/",s,"_FBO.txt"),append=ifelse(b=="OdorBlock1",FALSE,TRUE),quote=F,col.names=F,row.names=F)
    
    ## For UnFamiliar
    indU <- red.data$Odor[red.data$Running==b]=="UBO"
    write.table(t(timing2[indU]),file=paste0("TimingFiles/",s,"_UBO.txt"),append=ifelse(b=="OdorBlock1",FALSE,TRUE),quote=F,col.names=F,row.names=F)
    
    ## For Clean Air
    indCA <- red.data$Odor[red.data$Running==b]=="CA"
    write.table(t(timing2[indCA]),file=paste0("TimingFiles/",s,"_CA.txt"),append=ifelse(b=="OdorBlock1",FALSE,TRUE),quote=F,col.names=F,row.names=F)
    
    ## For Mask
    indM <- red.data$Odor[red.data$Running==b]=="MASK"
    write.table(t(timing2[indM]),file=paste0("TimingFiles/",s,"_MASK.txt"),append=ifelse(b=="OdorBlock1",FALSE,TRUE),quote=F,col.names=F,row.names=F)
    }

}
