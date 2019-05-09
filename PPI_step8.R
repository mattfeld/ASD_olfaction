library(tiff)
library(reshape2)
library(ez)



### --- Notes
#




###################
# Set up
###################

parDir <- "/Volumes/Yorick/Nate_work/AutismOlfactory/Analyses/"

doWrite <- 1
doGraphs <- 1

etacDir <- paste0(parDir,"grpAnalysis/")
etacData_location <- paste0(etacDir,"MVM_betas/")
etacData_list <- read.table(paste0(etacData_location,"All_List.txt"))
etac_outDir <- etacData_location
etac_statsDir <- paste0(etacDir,"MVM_stats/")




###################
# Functions
###################

SE.Function <- function(x,plot_data){
  SD <- sd(plot_data[,x])/sqrt(length(plot_data[,x]))
  return(SD)
}

# Graph.Function <- function(DF,output_name,maskN,out_place){
#   
#   TITLE <- maskN
#   MEANS <- colMeans(DF)
#   E.BARS<-NA
#   for(a in 1:dim(DF)[2]){
#     E.BARS[a] <- SE.Function(a,DF)
#   }
#   RANGE <- range(c(MEANS,MEANS-E.BARS,MEANS+E.BARS,0))
#   
#   if(grepl("ns_stats",out_place)==T){
#     ROI <- NsNames.Function(maskN)
#     XNAMES <- GraphNames.Function(output_name)
#   }else if(grepl("etac_stats",out_place)==T){
#     ROI <- EtacNames.Function(output_name,maskN)
#     XNAMES <- GraphEtacNames.Function(output_name)
#   }else if(grepl("sub_stats",out_place)==T){
#     ROI <- maskN
#     XNAMES <- GraphNames.Function(output_name)
#   }
#   
#   plotable <- matrix(0,nrow=2,ncol=num.betas)
#   plotable[1,] <- MEANS
#   plotable[2,] <- E.BARS
#   
#   if(doWrite == 1){
#     graphOut <- paste0(out_place,"Graph_",output_name,"_",TITLE,".tiff")
#     bitmap(graphOut, width = 6.5, units = 'in', type="tiff24nc", res=1200)
#   }
#   barCenters <- barplot(plotable[1,], names.arg = c(XNAMES), main=ROI, ylab="Beta Coefficient",ylim=RANGE)
#   segments(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS)
#   arrows(barCenters, MEANS-E.BARS, barCenters, MEANS+E.BARS, lwd = 1, angle = 90, code = 3, length = 0.05)
#   set.pos <- rowMeans(plotable); if(set.pos[1]>0){POS<-3}else{POS<-1}
#   text(barCenters,0,round(plotable[1,],4),cex=1,pos=POS,font=2)
#   if(doWrite == 1){
#     dev.off()
#   }
# }




###################
# ETAC
###################
# # For testing
# i <- "All_Betas_FUMC_2.txt"
# j <- "Betas_FUMC_2_LINS.txt"

for(i in t(etacData_list)){
  
  beta_list <- read.table(paste0(etacData_location,i))

  for(j in t(beta_list)){
    
    ### Get, clean data
    raw_data <- read.delim2(paste0(etacData_location,j),header=F)
    
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
    writeLines(output,paste0(etac_statsDir, "Stats_", j))
  }
}

