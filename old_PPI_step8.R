
library(tiff)
library(reshape2)
library(ez)



# FBO*UBO: Seed 1-LAG
# FBO*UBO:   RPF 

### Set up
doWrite <- 1

parDir <- "/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/"
aoDir <- paste0(parDir,"grpAnalysis/4COV_analysis/")
aoData_location <- paste0(aoDir,"MVM_betas/")
aoData_list <- read.table(paste0(aoData_location,"All_List.txt"))
ao_statsDir <- paste0(aoDir,"MVM_stats/")



# For testing
# i <- "All_Betas_FUMC_1.txt"
# j <- "Betas_FUMC_1_LAG.txt"

for(i in t(aoData_list)){
  
  beta_list <- read.table(paste0(aoData_location,i))
  
  for(j in t(beta_list)){
    
    ### Get, clean data
    raw_data <- read.delim2(paste0(aoData_location,j),header=F)
    
    # num subjects
    ind.subj <- grep("File", raw_data[,1])
    num.subj <- as.numeric(length(ind.subj))
    
    # num betas
    ind.beta <- grep("Int", raw_data[,2])
    num.betas <- as.numeric(length(ind.beta)/num.subj)
    
    
    ### fill df
    df <- matrix(0,ncol=num.betas+1,nrow=num.subj)
    
    # group
    count <- 1 
    for (k in 1:length(ind.subj)) {
      if(grepl("sub-1", raw_data[ind.subj[k],1])==T){
        df[count,1] <- "Con"
      }else{
        df[count,1] <- "Aut"
      }
      count <- count+1
    }
    
    # data
    # patch for multiple betas
    if(num.betas==1){
      df[,2] <- as.numeric(as.character(raw_data[ind.beta,3]))
    }else if(num.betas==2){
      ind.FBO <- grep("Int_FBO", raw_data[,2])
      ind.UBO <- grep("Int_UBO", raw_data[,2])
      df[,2] <- as.numeric(as.character(raw_data[ind.FBO,3]))
      df[,3] <- as.numeric(as.character(raw_data[ind.UBO,3]))
    }
    
    
    
    ### Stats
    # wilcox on group x single odorant
    # 2 x 2 anova on group x odorants (F/UBO)
    
    ind.con <- grep("Con", df[,1])
    ind.aut <- grep("Aut", df[,1])
    
    if(num.betas==1){
      
      con_mean <- round(mean(as.numeric(df[ind.con,2])),1)
      aut_mean <- round(mean(as.numeric(df[ind.aut,2])),1)
      hold_out <- wilcox.test(as.numeric(df[ind.con,2]), as.numeric(df[ind.aut,2]))
      
      output <- c("Con Mean", con_mean, "Aut Mean", aut_mean)
      output <- c(output, capture.output(print(hold_out)))
      
    }else if(num.betas==2){
      
      df.long <- as.data.frame(matrix(NA,nrow=num.subj*num.betas,ncol=4))
      names(df.long) <- c("Subj","Group","Stim","Data")
      df.long[,1] <- rep(1:num.subj, num.betas)
      df.long[,2] <- rep(df[,1],num.betas)
      df.long[,3] <- c(rep("FBO",num.subj),rep("UBO",num.subj))
      df.long[,4] <- as.numeric(c(df[,2],df[,3]))
      
      stats <- ezANOVA(df.long,dv=Data,wid=Subj,within=Stim,between=Group,type='III')
      
      output <- c("Group by Stim")
      output <- c(output, capture.output(print(stats)))
      
      con_mean_FBO <- round(mean(as.numeric(df[ind.con,2])),1)
      aut_mean_FBO <- round(mean(as.numeric(df[ind.aut,2])),1)
      hold_out_FBO <- wilcox.test(as.numeric(df[ind.con,2]), as.numeric(df[ind.aut,2]))
      
      output <- c(output, "Con Mean FBO", con_mean_FBO, "Aut Mean FBO", aut_mean_FBO)
      output <- c(output, capture.output(print(hold_out_FBO)))
      
      con_mean_UBO <- round(mean(as.numeric(df[ind.con,3])),1)
      aut_mean_UBO <- round(mean(as.numeric(df[ind.aut,3])),1)
      hold_out_UBO <- wilcox.test(as.numeric(df[ind.con,3]), as.numeric(df[ind.aut,2]))
      
      output <- c(output, "Con Mean UBO", con_mean_UBO, "Aut Mean UBO", aut_mean_UBO)
      output <- c(output, capture.output(print(hold_out_UBO)))
    }
    
    if(doWrite == 1){
      writeLines(output,paste0(ao_statsDir, "Stats_", j))
    }
    
    
    ### Graph
    plotable <- matrix(0,nrow=2,ncol=2*num.betas)
    # colnames(plotable) <- c("Control","Autistic")
    
    con_mean <- aut_mean <- NULL
    con_sd <- aut_sd <- NULL
    for(k in 1:num.betas){
      con_mean <- c(con_mean, mean(as.numeric(df[ind.con,1+k])))
      con_sd <- c(con_sd,sd(as.numeric(df[ind.con,1+k]))/sqrt(length(ind.con)))
      
      aut_mean <- c(aut_mean, mean(as.numeric(df[ind.aut,1+k])))
      aut_sd <- c(aut_sd, sd(as.numeric(df[ind.aut,1+k]))/sqrt(length(ind.aut)))
    }
    
    plotable[1,] <- c(con_mean,aut_mean)
    plotable[2,] <- c(con_sd,aut_sd)
    
    if(doWrite == 1){
      tmp <- gsub("\\..*","",j)
      graphOut <- paste0(ao_statsDir, "Graph_", tmp, ".tiff")
      bitmap(graphOut, width = 6.5, units = 'in', type="tiff24nc", res=1200)
    }
    
    hold <- gsub("^.*?_","",j); decon <- gsub("_.*$","",hold)
    hold2 <- gsub("^.*?_","",hold); seed <- gsub("_.*$","",hold2)
    hold3 <- gsub("^.*?_","",hold2); clust <- gsub("\\..*","",hold3)
    
    # hardcode stim since so few
    if(decon == "FUMvC"){
      stim <- "Odor"
    }else{
      stim <- "UBO"
    }
    
    MEANS <- matrix(plotable[1,],nrow=num.betas,byrow=T)
    E.BARS <- matrix(plotable[2,],nrow=num.betas,byrow=T)
    RANGE <- range(c(MEANS,MEANS-E.BARS,MEANS+E.BARS,0))
    if(num.betas==1){
      MAIN <- paste0(stim, ": Seed ", seed, "-", clust)
    }else{
      MAIN <- paste0("FBO*UBO", ": Seed ", seed, "-", clust)
    }
    
    
    #barCenters <- barplot(MEANS, main=MAIN, ylab="Parameter Estimate", ylim=RANGE,beside=T,names.arg = rep(c("Control","Autism"),num.betas),sub="FBO                                              UBO")
    barCenters <- barplot(MEANS, main=MAIN, ylab="Parameter Estimate", ylim=RANGE,beside=T,names.arg = rep(c("Control","Autism"),num.betas))
    if(num.betas==2){
      mtext(side=1,c("FBO","UBO"),at= c(2,5),line=3)
    }
    
    segments(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS)
    arrows(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS, lwd = 1, angle = 90, code = 3, length = 0.05)
    
    
    if(doWrite == 1){
      dev.off()
    }
  }
}
