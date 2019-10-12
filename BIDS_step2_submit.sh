#!/bin/bash


###??? update these
workDir=~/compute/AutismOlfactory
scriptDir=${workDir}/code
slurmDir=${workDir}/derivatives/Slurm_out
time=`date '+%Y_%m_%d-%H_%M_%S'`
outDir=${slurmDir}/BID2_${time}

mkdir -p $outDir




### Write dataset_description.json
# This will request input
if [ ! -s ${workDir}/rawdata/dataset_description.json ]; then

	echo -e "\nNote: title below must be supplied in quotations"
	echo -e "\te.g. \"This is my title\"\n"
	read -p 'Please enter title of the manuscript:' title

	echo -e "\n\nNote: authors must be within quotes and separated by a comma & space"
	echo -e "\te.g. \"Nate Muncy\", \"Brock Kirwan\"\n"
	read -p 'Please enter authors:' authors

	cat > ${workDir}/rawdata/dataset_description.json << EOF
{
	"Name": $title,
	"BIDSVersion": "1.1.1",
	"License": "CCo",
	"Authors": [$authors]
}
EOF
fi



cd ${workDir}/rawdata

for i in sub*; do
	if [ ! -f ${subj}/anat/${i}_T1w.json ]; then

	    sbatch \
	    -o ${outDir}/output_TS1_${i}.txt \
	    -e ${outDir}/error_TS1_${i}.txt \
	    ${scriptDir}/BIDS_step2_organize.sh $i

	    sleep 1
	fi
done
