
library(tiff)
library(reshape2)
library(ez)





### Set up
doWrite <- 1

parDir <- "/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/"
aoDir <- paste0(parDir,"grpAnalysis/")
aoData_location <- paste0(aoDir,"MVM_betas/")
aoData_list <- read.table(paste0(aoData_location,"All_List.txt"))
ao_statsDir <- paste0(aoDir,"MVM_stats/")



# For testing
# i <- "All_Betas_FUMC_2.txt"
# j <- "Betas_FUMC_2_LINS.txt"

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
    df[,2] <- as.numeric(as.character(raw_data[ind.beta,3]))


    ### Stats
    ind.con <- grep("Con", df[,1])
    ind.aut <- grep("Aut", df[,1])
    
    con_mean <- round(mean(as.numeric(df[ind.con,2])),1)
    aut_mean <- round(mean(as.numeric(df[ind.aut,2])),1)
    hold_out <- wilcox.test(as.numeric(df[ind.con,2]), as.numeric(df[ind.aut,2]))
    
    output <- c("Con Mean", con_mean, "Aut Mean", aut_mean)
    output <- c(output, capture.output(print(hold_out)))
    if(doWrite == 1){
      writeLines(output,paste0(ao_statsDir, "Stats_", j))
    }
    
    
    ### Graph
    plotable <- matrix(0,nrow=2,ncol=2)
    colnames(plotable) <- c("Control","Autistic")
    plotable[1,] <- c(con_mean,aut_mean)
    
    con_sd <- sd(df[ind.con,2])/sqrt(length(ind.con))
    aut_sd <- sd(df[ind.aut,2])/sqrt(length(ind.aut))
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
    
    MEANS <- plotable[1,]
    E.BARS <- plotable[2,]
    RANGE <- range(c(MEANS,MEANS-E.BARS,MEANS+E.BARS,0))
    
    MAIN <- paste0(stim, ": Seed ", seed, "-", clust)
    
    barCenters <- barplot(plotable[1,], main=MAIN, ylab="Parameter Estimate", ylim=RANGE)
    segments(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS)
    arrows(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS, lwd = 1, angle = 90, code = 3, length = 0.05)
    
    if(doWrite == 1){
      dev.off()
    }
  }
}
