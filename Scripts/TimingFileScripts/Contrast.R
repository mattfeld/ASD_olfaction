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
  timing.contrast <- NULL
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
    expanding <- rep(c("ITI1","Baseline","CON","CON","CON","Response1","Baseline","Response2"),length.label)
    expand.odor <- rep(red.data$Odor[i],sum(length.label))
    ### Populating up the Timing Files per trial
    timing.hold <- matrix(0,nrow=length(expanding),ncol=1)
    if(red.data$Odor[i]=="FBO"){
      timing.hold[which(expanding=="CON")] <- 1
    }
    if(red.data$Odor[i]=="UBO"){
      timing.hold[which(expanding=="CON")] <- -1
    }
    timing.contrast <- rbind(timing.contrast,timing.hold) # subject timing files
    
  }
  
  write.table(timing.contrast,paste0("Contrast/",s,"_ppi.txt"),quote=F,col.names=F,row.names = F)
 
}
