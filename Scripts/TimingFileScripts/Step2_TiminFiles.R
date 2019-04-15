



workDir <- "/Volumes/Yorick/Nate_work/AutismOlfactory/"
subjList <- read.delim(paste0(workDir,"Subj_List.txt"))
subjList <- t(subjList)


for(j in subjList){
  
  h.CA <- read.delim(paste0(workDir,"BO",j,"/ppi_data/",j,"_CA.txt"))
}