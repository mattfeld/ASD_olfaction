
library(tiff)
library(ghostscript)
library(reshape2)
library(ez)
library(ggplot2)


### Set parameters
dataDir <- "/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/ppiAnalysis/mvm_stats/"
outDir <- dataDir

write.out <- 0
graph.out <- 1


### Do it
# j <- "8a_G.CUF_mask_1"


###### maybe add a loop at the end of step11.2 so this is more efficient

for(j in c("11_G.MUF_mask_1","11_G.UF_mask_1","1_G.M_mask_1","3_G.UF_mask_1","8a_G.CUF_mask_1","8a_G.C_mask_1","8a_G.C_mask_2","8b_G.M_mask_1","8b_G.M_mask_2")){

  ### get info
  df.raw <- read.delim(paste0(dataDir,"Betas_Seed_",j,".txt"),header=F)
  
  #mask
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
  
  # colnames
  if(grepl("G.M_",j)==T){
    colnames(Ndata) <- c("Mask","Group")
  }else if(grepl("G.C_",j)==T){
    colnames(Ndata) <- c("CA","Group")
  }else if(grepl("G.UF_",j)==T){
    colnames(Ndata) <- c("FBO","UBO","Group")
  }else if(grepl("G.CUF_",j)==T){
    colnames(Ndata) <- c("FBO","UBO","CA","Group")
  }else if(grepl("G.MUF_",j)==T){
    colnames(Ndata) <- c("FBO","UBO","Mask","Group")
  }
  
  
  ### Run stats
  ind.C <- grep("C",Ndata[,dim(Ndata)[2]])
  ind.A <- grep("A",Ndata[,dim(Ndata)[2]])
  
  # TTests
  if(num.inter == 1){
    
    g.A <- as.numeric(Ndata[ind.A,1])
    g.C <- as.numeric(Ndata[ind.C,1])
    t.out <- t.test(g.C, g.A)
    
    if(write.out == 1) {
      output <- capture.output(print(t.out))
      writeLines(output,paste0(outDir,"Stats_TTest_",j,".txt"))
    }
    
    
    
    ## Graph
    if(graph.out == 1){
      
      SE <- matrix(0,nrow=1,ncol=2)
      SE[,1] <- sd(Ndata[ind.C,1])/sqrt(length(Ndata[ind.C,1]))
      SE[,2] <- sd(Ndata[ind.A,1])/sqrt(length(Ndata[ind.A,1]))
      
      TITLE <- j
      MEANS <- c(mean(as.numeric(Ndata[ind.C,1])),mean(as.numeric(Ndata[ind.A,1])))
      E.BARS <- SE
      RANGE <- range(c(MEANS,MEANS-E.BARS,MEANS+E.BARS,0))
      XNAMES <- c("Control", "Autism")
      if(grepl("G.C_",j)==T){
        ROI <- "Clean Air"
      }else if(grepl("G.M_",j)==T){
        ROI <- "Mask Odor"
      }
      
      plotable <- matrix(0,nrow=2,ncol=2)
      plotable[1,] <- MEANS
      plotable[2,] <- E.BARS
      
      graphOut <- paste0(outDir,"Graph_",TITLE,".tiff")
      bitmap(graphOut, width = 6.5, units = 'in', type="tiff24nc", res=1200)
      barCenters <- barplot(plotable[1,], names.arg = c(XNAMES), main=ROI, ylab="Difference from Baseline",ylim=RANGE)
      segments(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS)
      arrows(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS, lwd = 1, angle = 90, code = 3, length = 0.05)
      dev.off()
    }
  }
  
  
  # BW ANOVA
  if(num.inter == 2){
    
    hold.out <- list()
    hold.out[[1]] <- j
    
    df.hold <- matrix(NA,ncol = 4, nrow = 2*num.subj)
    df.hold <- as.data.frame(df.hold)
    colnames(df.hold) <- c("Subj","Group","Behavior","Value")
    
    df.hold[,1] <- as.factor(rep(1:num.subj,2))
    df.hold[,2] <- as.factor(rep(c(rep("A",length(ind.A)),rep("C",length(ind.C))),2))
    df.hold[,3] <- as.factor(c(rep(colnames(Ndata)[1],num.subj),rep(colnames(Ndata)[2],num.subj)))
    df.hold[1:num.subj,4] <- Ndata[,1]
    df.hold[(num.subj+1):(2*num.subj),4] <- Ndata[,2]
    df.hold$Value <- as.numeric(df.hold$Value)
    
    hold.out[[2]] <- ezANOVA(df.hold,dv=Value,wid=Subj,within=Behavior,between=Group,type='III')
    
    ## Post-hoc
    hold.out[[3]] <- c("Comp:", colnames(Ndata)[1], " CvA")
    hold.out[[4]] <- t.test(as.numeric(Ndata[ind.C,1]),as.numeric(Ndata[ind.A,1]),paired=F)
    hold.out[[5]] <- c("Comp:", colnames(Ndata)[2], " CvA")
    hold.out[[6]] <- t.test(as.numeric(Ndata[ind.C,2]),as.numeric(Ndata[ind.A,2]),paired=F)
    
    if(write.out == 1){
      output <- capture.output(print(hold.out))
      writeLines(output,paste0(outDir,"Stats_BW_",j,".txt"))
    }

    
    
    ## Graph
    if(graph.out == 1){
      
      SE <- matrix(0,nrow=1,ncol=4)
      SE[,1] <- sd(Ndata[ind.C,1])/sqrt(length(Ndata[ind.C,1]))
      SE[,2] <- sd(Ndata[ind.A,1])/sqrt(length(Ndata[ind.A,1]))
      SE[,3] <- sd(Ndata[ind.C,2])/sqrt(length(Ndata[ind.C,2]))
      SE[,4] <- sd(Ndata[ind.A,2])/sqrt(length(Ndata[ind.A,2]))
      
      TITLE <- j
      MEANS <- c(mean(as.numeric(Ndata[ind.C,1])),mean(as.numeric(Ndata[ind.A,1])),mean(as.numeric(Ndata[ind.C,2])),mean(as.numeric(Ndata[ind.A,2])))
      E.BARS <- SE
      RANGE <- range(c(MEANS,MEANS-E.BARS,MEANS+E.BARS,0))
      ROI <- "Odorant by Group"
      
      plotable <- matrix(0,nrow=2,ncol=4)
      plotable[1,] <- MEANS
      plotable[2,] <- E.BARS
      
      graphOut <- paste0(outDir,"Graph_",TITLE,".tiff")
      bitmap(graphOut, width = 6.5, units = 'in', type="tiff24nc", res=1200)
      par(mar=c(8,5,4,2),family="Times New Roman")
      barCenters <- barplot(rbind(plotable[1,1:2],plotable[1,3:4]),  main=ROI, ylab="Difference from Baseline",ylim=RANGE,col=c("darkblue","darkred"),beside=T,names.arg=colnames(Ndata)[1:2])
      
      segments(barCenters, rbind(MEANS[1:2],MEANS[3:4])- rbind(E.BARS[1:2],E.BARS[3:4]), barCenters, rbind(MEANS[1:2],MEANS[3:4])+rbind(E.BARS[1:2],E.BARS[3:4]))
      arrows(barCenters, rbind(MEANS[1:2],MEANS[3:4])- rbind(E.BARS[1:2],E.BARS[3:4]), barCenters, rbind(MEANS[1:2],MEANS[3:4])+rbind(E.BARS[1:2],E.BARS[3:4]), lwd = 1, angle = 90, code = 3, length = 0.05)
      legend("topright",fill=c("darkblue","darkred"),c("Control","Autism"))
      dev.off()
    }
  }
  
  
  if(num.inter == 3){
    
    hold.out <- list()
    hold.out[[1]] <- j
    
    df.hold <- matrix(NA,ncol = 4, nrow = 3*num.subj)
    df.hold <- as.data.frame(df.hold)
    colnames(df.hold) <- c("Subj","Group","Behavior","Value")
    
    df.hold[,1] <- as.factor(rep(1:num.subj,3))
    df.hold[,2] <- as.factor(rep(c(rep("A",length(ind.A)),rep("C",length(ind.C))),3))
    df.hold[,3] <- as.factor(c(rep(colnames(Ndata)[1],num.subj),rep(colnames(Ndata)[2],num.subj),rep(colnames(Ndata)[3],num.subj)))
    df.hold[1:num.subj,4] <- Ndata[,1]
    df.hold[(num.subj+1):(2*num.subj),4] <- Ndata[,2]
    df.hold[(2*num.subj+1):(3*num.subj),4] <- Ndata[,3]
    df.hold$Value <- as.numeric(df.hold$Value)
    
    hold.out[[2]] <- ezANOVA(df.hold,dv=Value,wid=Subj,within=Behavior,between=Group,type='III')
    
    ## Post-hoc
    hold.out[[3]] <- c("Comp:", colnames(Ndata)[1], " CvA")
    hold.out[[4]] <- t.test(as.numeric(Ndata[ind.C,1]),as.numeric(Ndata[ind.A,1]),paired=F)
    hold.out[[5]] <- c("Comp:", colnames(Ndata)[2], " CvA")
    hold.out[[6]] <- t.test(as.numeric(Ndata[ind.C,2]),as.numeric(Ndata[ind.A,2]),paired=F)
    hold.out[[7]] <- c("Comp:", colnames(Ndata)[3], " CvA")
    hold.out[[8]] <- t.test(as.numeric(Ndata[ind.C,3]),as.numeric(Ndata[ind.A,3]),paired=F)
    
    if(write.out == 1){
      output <- capture.output(print(hold.out))
      writeLines(output,paste0(outDir,"Stats_BW_",j,".txt"))
    }

    
    ## Graph
    if(graph.out == 1){
      
      SE <- matrix(0,nrow=1,ncol=6)
      SE[,1] <- sd(Ndata[ind.C,1])/sqrt(length(Ndata[ind.C,1]))
      SE[,2] <- sd(Ndata[ind.A,1])/sqrt(length(Ndata[ind.A,1]))
      SE[,3] <- sd(Ndata[ind.C,2])/sqrt(length(Ndata[ind.C,2]))
      SE[,4] <- sd(Ndata[ind.A,2])/sqrt(length(Ndata[ind.A,2]))
      SE[,5] <- sd(Ndata[ind.C,3])/sqrt(length(Ndata[ind.C,3]))
      SE[,6] <- sd(Ndata[ind.A,3])/sqrt(length(Ndata[ind.A,3]))
      
      TITLE <- j
      MEANS <- c(mean(as.numeric(Ndata[ind.C,1])),mean(as.numeric(Ndata[ind.A,1])),mean(as.numeric(Ndata[ind.C,2])),mean(as.numeric(Ndata[ind.A,2])),mean(as.numeric(Ndata[ind.C,3])),mean(as.numeric(Ndata[ind.A,3])))
      E.BARS <- SE
      RANGE <- range(c(MEANS,MEANS-E.BARS,MEANS+E.BARS,0))
      ROI <- "Odorant by Group"
      
      plotable <- matrix(0,nrow=2,ncol=6)
      plotable[1,] <- MEANS
      plotable[2,] <- E.BARS
      
      graphOut <- paste0(outDir,"Graph_",TITLE,".tiff")
      bitmap(graphOut, width = 6.5, units = 'in', type="tiff24nc", res=1200)
      par(family="Times New Roman")
      barCenters <- barplot(cbind(plotable[1,1:2],plotable[1,3:4],plotable[1,5:6]), main=ROI, ylab="Difference from Baseline",ylim=RANGE,col=c("darkblue","darkred"),beside=T,names.arg=colnames(Ndata)[1:3])
      
      segments(barCenters, cbind(MEANS[1:2],MEANS[3:4],MEANS[5:6])- cbind(E.BARS[1:2],E.BARS[3:4],E.BARS[5:6]), barCenters, cbind(MEANS[1:2],MEANS[3:4],MEANS[5:6])+cbind(E.BARS[1:2],E.BARS[3:4],E.BARS[5:6]))
      arrows(barCenters, cbind(MEANS[1:2],MEANS[3:4],MEANS[5:6])- cbind(E.BARS[1:2],E.BARS[3:4],E.BARS[5:6]), barCenters, cbind(MEANS[1:2],MEANS[3:4],MEANS[5:6])+cbind(E.BARS[1:2],E.BARS[3:4],E.BARS[5:6]), lwd = 1, angle = 90, code = 3, length = 0.05)
      legend("topright",fill=c("darkblue","darkred"),c("Control","Autism"))
      dev.off()
    }
  }
}




