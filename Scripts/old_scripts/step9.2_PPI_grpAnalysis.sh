#!/bin/bash


# Written by Nathan Muncy on 7/3/18
#
#
#  Assumes step9 has alreaady been run, uses output from that script




### Set up
workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
ppiDir=${workDir}/Analyses/ppiAnalysis
refDir=${workDir}/BO1048/ppi_data

mask=${ppiDir}/Template_GM_mask+tlrc


# Make lists
cd $refDir

c=0; for i in FINAL_Indiv_{?,??}+tlrc.HEAD; do
    fiList[$c]=${i%.*}
    let c=$[$c+1]
done



### For each seed compare 'Inter' coefficients between groups
cd $ppiDir

for i in ${fiList[@]}; do

    scan=$i
	tmp=${i#*_}
	out=MVM_${tmp%+*}
 	#a=29; b=26; c=35; d=32      # This should be updated since there was that bug in 8.2

 	if [ ! -f ${out}+tlrc.HEAD ]; then

 		3dMVM -prefix $out -jobs 6 -mask $mask \
 		-bsVars 'Group' \
 		-wsVars 'Stim' \
 		-num_glt 4 \
 		-gltLabel 1 G.F  -gltCode 1 'Group: 1*C -1*A Stim: 1*FBO' \
 		-gltLabel 2 G.U  -gltCode 2 'Group: 1*C -1*A Stim: 1*UBO' \
 		-gltLabel 3 G.C  -gltCode 3 'Group: 1*C -1*A Stim: 1*CA' \
 		-gltLabel 4 G.M  -gltCode 4 'Group: 1*C -1*A Stim: 1*MASK' \
 		-num_glf 4 \
 		-glfLabel 1 G.UF  -glfCode 1 'Group : 1*C -1*A Stim : 1*UBO -1*FBO' \
		-glfLabel 2 G.MC  -glfCode 2 'Group : 1*C -1*A Stim : 1*MASK -1*CA' \
		-glfLabel 3 G.CUF -glfCode 3 'Group : 1*C -1*A Stim : 1*CA -1*UBO & 1*CA -1*FBO' \
		-glfLabel 4 G.MUF -glfCode 4 'Group : 1*C -1*A Stim : 1*MASK -1*UBO & 1*MASK -1*FBO' \
 		-dataTable \
 		Subj	Group	Stim	InputFile \
		BO1048	C	UBO		${workDir}/BO1048/ppi_data/"${scan}[$a]" \
		BO1048	C	FBO		${workDir}/BO1048/ppi_data/"${scan}[$b]" \
		BO1048	C	CA		${workDir}/BO1048/ppi_data/"${scan}[$c]" \
		BO1048	C	MASK	${workDir}/BO1048/ppi_data/"${scan}[$d]" \
		BO1055	C	UBO		${workDir}/BO1055/ppi_data/"${scan}[$a]" \
		BO1055	C	FBO		${workDir}/BO1055/ppi_data/"${scan}[$b]" \
		BO1055	C	CA		${workDir}/BO1055/ppi_data/"${scan}[$c]" \
		BO1055	C	MASK	${workDir}/BO1055/ppi_data/"${scan}[$d]" \
		BO1063	C	UBO		${workDir}/BO1063/ppi_data/"${scan}[$a]" \
		BO1063	C	FBO		${workDir}/BO1063/ppi_data/"${scan}[$b]" \
		BO1063	C	CA		${workDir}/BO1063/ppi_data/"${scan}[$c]" \
		BO1063	C	MASK	${workDir}/BO1063/ppi_data/"${scan}[$d]" \
		BO1065	C	UBO		${workDir}/BO1065/ppi_data/"${scan}[$a]" \
		BO1065	C	FBO		${workDir}/BO1065/ppi_data/"${scan}[$b]" \
		BO1065	C	CA		${workDir}/BO1065/ppi_data/"${scan}[$c]" \
		BO1065	C	MASK	${workDir}/BO1065/ppi_data/"${scan}[$d]" \
		BO1086	C	UBO		${workDir}/BO1086/ppi_data/"${scan}[$a]" \
		BO1086	C	FBO		${workDir}/BO1086/ppi_data/"${scan}[$b]" \
		BO1086	C	CA		${workDir}/BO1086/ppi_data/"${scan}[$c]" \
		BO1086	C	MASK	${workDir}/BO1086/ppi_data/"${scan}[$d]" \
		BO1104	C	UBO		${workDir}/BO1104/ppi_data/"${scan}[$a]" \
		BO1104	C	FBO		${workDir}/BO1104/ppi_data/"${scan}[$b]" \
		BO1104	C	CA		${workDir}/BO1104/ppi_data/"${scan}[$c]" \
		BO1104	C	MASK	${workDir}/BO1104/ppi_data/"${scan}[$d]" \
		BO1108	C	UBO		${workDir}/BO1108/ppi_data/"${scan}[$a]" \
		BO1108	C	FBO		${workDir}/BO1108/ppi_data/"${scan}[$b]" \
		BO1108	C	CA		${workDir}/BO1108/ppi_data/"${scan}[$c]" \
		BO1108	C	MASK	${workDir}/BO1108/ppi_data/"${scan}[$d]" \
		BO1109	C	UBO		${workDir}/BO1109/ppi_data/"${scan}[$a]" \
		BO1109	C	FBO		${workDir}/BO1109/ppi_data/"${scan}[$b]" \
		BO1109	C	CA		${workDir}/BO1109/ppi_data/"${scan}[$c]" \
		BO1109	C	MASK	${workDir}/BO1109/ppi_data/"${scan}[$d]" \
		BO1113	C	UBO		${workDir}/BO1113/ppi_data/"${scan}[$a]" \
		BO1113	C	FBO		${workDir}/BO1113/ppi_data/"${scan}[$b]" \
		BO1113	C	CA		${workDir}/BO1113/ppi_data/"${scan}[$c]" \
		BO1113	C	MASK	${workDir}/BO1113/ppi_data/"${scan}[$d]" \
		BO1115	C	UBO		${workDir}/BO1115/ppi_data/"${scan}[$a]" \
		BO1115	C	FBO		${workDir}/BO1115/ppi_data/"${scan}[$b]" \
		BO1115	C	CA		${workDir}/BO1115/ppi_data/"${scan}[$c]" \
		BO1115	C	MASK	${workDir}/BO1115/ppi_data/"${scan}[$d]" \
		BO1116	C	UBO		${workDir}/BO1116/ppi_data/"${scan}[$a]" \
		BO1116	C	FBO		${workDir}/BO1116/ppi_data/"${scan}[$b]" \
		BO1116	C	CA		${workDir}/BO1116/ppi_data/"${scan}[$c]" \
		BO1116	C	MASK	${workDir}/BO1116/ppi_data/"${scan}[$d]" \
		BO1117	C	UBO		${workDir}/BO1117/ppi_data/"${scan}[$a]" \
		BO1117	C	FBO		${workDir}/BO1117/ppi_data/"${scan}[$b]" \
		BO1117	C	CA		${workDir}/BO1117/ppi_data/"${scan}[$c]" \
		BO1117	C	MASK	${workDir}/BO1117/ppi_data/"${scan}[$d]" \
		BO1118	C	UBO		${workDir}/BO1118/ppi_data/"${scan}[$a]" \
		BO1118	C	FBO		${workDir}/BO1118/ppi_data/"${scan}[$b]" \
		BO1118	C	CA		${workDir}/BO1118/ppi_data/"${scan}[$c]" \
		BO1118	C	MASK	${workDir}/BO1118/ppi_data/"${scan}[$d]" \
		BO1119	C	UBO		${workDir}/BO1119/ppi_data/"${scan}[$a]" \
		BO1119	C	FBO		${workDir}/BO1119/ppi_data/"${scan}[$b]" \
		BO1119	C	CA		${workDir}/BO1119/ppi_data/"${scan}[$c]" \
		BO1119	C	MASK	${workDir}/BO1119/ppi_data/"${scan}[$d]" \
		BO1120	C	UBO		${workDir}/BO1120/ppi_data/"${scan}[$a]" \
		BO1120	C	FBO		${workDir}/BO1120/ppi_data/"${scan}[$b]" \
		BO1120	C	CA		${workDir}/BO1120/ppi_data/"${scan}[$c]" \
		BO1120	C	MASK	${workDir}/BO1120/ppi_data/"${scan}[$d]" \
		BO1121	C	UBO		${workDir}/BO1121/ppi_data/"${scan}[$a]" \
		BO1121	C	FBO		${workDir}/BO1121/ppi_data/"${scan}[$b]" \
		BO1121	C	CA		${workDir}/BO1121/ppi_data/"${scan}[$c]" \
		BO1121	C	MASK	${workDir}/BO1121/ppi_data/"${scan}[$d]" \
		BO1126	C	UBO		${workDir}/BO1126/ppi_data/"${scan}[$a]" \
		BO1126	C	FBO		${workDir}/BO1126/ppi_data/"${scan}[$b]" \
		BO1126	C	CA		${workDir}/BO1126/ppi_data/"${scan}[$c]" \
		BO1126	C	MASK	${workDir}/BO1126/ppi_data/"${scan}[$d]" \
		BO1127	C	UBO		${workDir}/BO1127/ppi_data/"${scan}[$a]" \
		BO1127	C	FBO		${workDir}/BO1127/ppi_data/"${scan}[$b]" \
		BO1127	C	CA		${workDir}/BO1127/ppi_data/"${scan}[$c]" \
		BO1127	C	MASK	${workDir}/BO1127/ppi_data/"${scan}[$d]" \
		BO1128	C	UBO		${workDir}/BO1128/ppi_data/"${scan}[$a]" \
		BO1128	C	FBO		${workDir}/BO1128/ppi_data/"${scan}[$b]" \
		BO1128	C	CA		${workDir}/BO1128/ppi_data/"${scan}[$c]" \
		BO1128	C	MASK	${workDir}/BO1128/ppi_data/"${scan}[$d]" \
		BO1130	C	UBO		${workDir}/BO1130/ppi_data/"${scan}[$a]" \
		BO1130	C	FBO		${workDir}/BO1130/ppi_data/"${scan}[$b]" \
		BO1130	C	CA		${workDir}/BO1130/ppi_data/"${scan}[$c]" \
		BO1130	C	MASK	${workDir}/BO1130/ppi_data/"${scan}[$d]" \
		BO1131	C	UBO		${workDir}/BO1131/ppi_data/"${scan}[$a]" \
		BO1131	C	FBO		${workDir}/BO1131/ppi_data/"${scan}[$b]" \
		BO1131	C	CA		${workDir}/BO1131/ppi_data/"${scan}[$c]" \
		BO1131	C	MASK	${workDir}/BO1131/ppi_data/"${scan}[$d]" \
		BO1133	C	UBO		${workDir}/BO1133/ppi_data/"${scan}[$a]" \
		BO1133	C	FBO		${workDir}/BO1133/ppi_data/"${scan}[$b]" \
		BO1133	C	CA		${workDir}/BO1133/ppi_data/"${scan}[$c]" \
		BO1133	C	MASK	${workDir}/BO1133/ppi_data/"${scan}[$d]" \
		BO1134	C	UBO		${workDir}/BO1134/ppi_data/"${scan}[$a]" \
		BO1134	C	FBO		${workDir}/BO1134/ppi_data/"${scan}[$b]" \
		BO1134	C	CA		${workDir}/BO1134/ppi_data/"${scan}[$c]" \
		BO1134	C	MASK	${workDir}/BO1134/ppi_data/"${scan}[$d]" \
		BO1135	C	UBO		${workDir}/BO1135/ppi_data/"${scan}[$a]" \
		BO1135	C	FBO		${workDir}/BO1135/ppi_data/"${scan}[$b]" \
		BO1135	C	CA		${workDir}/BO1135/ppi_data/"${scan}[$c]" \
		BO1135	C	MASK	${workDir}/BO1135/ppi_data/"${scan}[$d]" \
		BO1137	C	UBO		${workDir}/BO1137/ppi_data/"${scan}[$a]" \
		BO1137	C	FBO		${workDir}/BO1137/ppi_data/"${scan}[$b]" \
		BO1137	C	CA		${workDir}/BO1137/ppi_data/"${scan}[$c]" \
		BO1137	C	MASK	${workDir}/BO1137/ppi_data/"${scan}[$d]" \
		BO1138	C	UBO		${workDir}/BO1138/ppi_data/"${scan}[$a]" \
		BO1138	C	FBO		${workDir}/BO1138/ppi_data/"${scan}[$b]" \
		BO1138	C	CA		${workDir}/BO1138/ppi_data/"${scan}[$c]" \
		BO1138	C	MASK	${workDir}/BO1138/ppi_data/"${scan}[$d]" \
		BO1140	C	UBO		${workDir}/BO1140/ppi_data/"${scan}[$a]" \
		BO1140	C	FBO		${workDir}/BO1140/ppi_data/"${scan}[$b]" \
		BO1140	C	CA		${workDir}/BO1140/ppi_data/"${scan}[$c]" \
		BO1140	C	MASK	${workDir}/BO1140/ppi_data/"${scan}[$d]" \
		BO606	A	UBO		${workDir}/BO606/ppi_data/"${scan}[$a]" \
		BO606	A	FBO		${workDir}/BO606/ppi_data/"${scan}[$b]" \
		BO606	A	CA		${workDir}/BO606/ppi_data/"${scan}[$c]" \
		BO606	A	MASK	${workDir}/BO606/ppi_data/"${scan}[$d]" \
		BO608	A	UBO		${workDir}/BO608/ppi_data/"${scan}[$a]" \
		BO608	A	FBO		${workDir}/BO608/ppi_data/"${scan}[$b]" \
		BO608	A	CA		${workDir}/BO608/ppi_data/"${scan}[$c]" \
		BO608	A	MASK	${workDir}/BO608/ppi_data/"${scan}[$d]" \
		BO618	A	UBO		${workDir}/BO618/ppi_data/"${scan}[$a]" \
		BO618	A	FBO		${workDir}/BO618/ppi_data/"${scan}[$b]" \
		BO618	A	CA		${workDir}/BO618/ppi_data/"${scan}[$c]" \
		BO618	A	MASK	${workDir}/BO618/ppi_data/"${scan}[$d]" \
		BO625	A	UBO		${workDir}/BO625/ppi_data/"${scan}[$a]" \
		BO625	A	FBO		${workDir}/BO625/ppi_data/"${scan}[$b]" \
		BO625	A	CA		${workDir}/BO625/ppi_data/"${scan}[$c]" \
		BO625	A	MASK	${workDir}/BO625/ppi_data/"${scan}[$d]" \
		BO632	A	UBO		${workDir}/BO632/ppi_data/"${scan}[$a]" \
		BO632	A	FBO		${workDir}/BO632/ppi_data/"${scan}[$b]" \
		BO632	A	CA		${workDir}/BO632/ppi_data/"${scan}[$c]" \
		BO632	A	MASK	${workDir}/BO632/ppi_data/"${scan}[$d]" \
		BO670	A	UBO		${workDir}/BO670/ppi_data/"${scan}[$a]" \
		BO670	A	FBO		${workDir}/BO670/ppi_data/"${scan}[$b]" \
		BO670	A	CA		${workDir}/BO670/ppi_data/"${scan}[$c]" \
		BO670	A	MASK	${workDir}/BO670/ppi_data/"${scan}[$d]" \
		BO674	A	UBO		${workDir}/BO674/ppi_data/"${scan}[$a]" \
		BO674	A	FBO		${workDir}/BO674/ppi_data/"${scan}[$b]" \
		BO674	A	CA		${workDir}/BO674/ppi_data/"${scan}[$c]" \
		BO674	A	MASK	${workDir}/BO674/ppi_data/"${scan}[$d]" \
		BO676	A	UBO		${workDir}/BO676/ppi_data/"${scan}[$a]" \
		BO676	A	FBO		${workDir}/BO676/ppi_data/"${scan}[$b]" \
		BO676	A	CA		${workDir}/BO676/ppi_data/"${scan}[$c]" \
		BO676	A	MASK	${workDir}/BO676/ppi_data/"${scan}[$d]" \
		BO683	A	UBO		${workDir}/BO683/ppi_data/"${scan}[$a]" \
		BO683	A	FBO		${workDir}/BO683/ppi_data/"${scan}[$b]" \
		BO683	A	CA		${workDir}/BO683/ppi_data/"${scan}[$c]" \
		BO683	A	MASK	${workDir}/BO683/ppi_data/"${scan}[$d]" \
		BO694	A	UBO		${workDir}/BO694/ppi_data/"${scan}[$a]" \
		BO694	A	FBO		${workDir}/BO694/ppi_data/"${scan}[$b]" \
		BO694	A	CA		${workDir}/BO694/ppi_data/"${scan}[$c]" \
		BO694	A	MASK	${workDir}/BO694/ppi_data/"${scan}[$d]" \
		BO695	A	UBO		${workDir}/BO695/ppi_data/"${scan}[$a]" \
		BO695	A	FBO		${workDir}/BO695/ppi_data/"${scan}[$b]" \
		BO695	A	CA		${workDir}/BO695/ppi_data/"${scan}[$c]" \
		BO695	A	MASK	${workDir}/BO695/ppi_data/"${scan}[$d]" \
		BO696	A	UBO		${workDir}/BO696/ppi_data/"${scan}[$a]" \
		BO696	A	FBO		${workDir}/BO696/ppi_data/"${scan}[$b]" \
		BO696	A	CA		${workDir}/BO696/ppi_data/"${scan}[$c]" \
		BO696	A	MASK	${workDir}/BO696/ppi_data/"${scan}[$d]" \
		BO698	A	UBO		${workDir}/BO698/ppi_data/"${scan}[$a]" \
		BO698	A	FBO		${workDir}/BO698/ppi_data/"${scan}[$b]" \
		BO698	A	CA		${workDir}/BO698/ppi_data/"${scan}[$c]" \
		BO698	A	MASK	${workDir}/BO698/ppi_data/"${scan}[$d]" \
		BO699	A	UBO		${workDir}/BO699/ppi_data/"${scan}[$a]" \
		BO699	A	FBO		${workDir}/BO699/ppi_data/"${scan}[$b]" \
		BO699	A	CA		${workDir}/BO699/ppi_data/"${scan}[$c]" \
		BO699	A	MASK	${workDir}/BO699/ppi_data/"${scan}[$d]" \
		BO700	A	UBO		${workDir}/BO700/ppi_data/"${scan}[$a]" \
		BO700	A	FBO		${workDir}/BO700/ppi_data/"${scan}[$b]" \
		BO700	A	CA		${workDir}/BO700/ppi_data/"${scan}[$c]" \
		BO700	A	MASK	${workDir}/BO700/ppi_data/"${scan}[$d]" \
		BO701	A	UBO		${workDir}/BO701/ppi_data/"${scan}[$a]" \
		BO701	A	FBO		${workDir}/BO701/ppi_data/"${scan}[$b]" \
		BO701	A	CA		${workDir}/BO701/ppi_data/"${scan}[$c]" \
		BO701	A	MASK	${workDir}/BO701/ppi_data/"${scan}[$d]" \
		BO703	A	UBO		${workDir}/BO703/ppi_data/"${scan}[$a]" \
		BO703	A	FBO		${workDir}/BO703/ppi_data/"${scan}[$b]" \
		BO703	A	CA		${workDir}/BO703/ppi_data/"${scan}[$c]" \
		BO703	A	MASK	${workDir}/BO703/ppi_data/"${scan}[$d]" \
		BO704	A	UBO		${workDir}/BO704/ppi_data/"${scan}[$a]" \
		BO704	A	FBO		${workDir}/BO704/ppi_data/"${scan}[$b]" \
		BO704	A	CA		${workDir}/BO704/ppi_data/"${scan}[$c]" \
		BO704	A	MASK	${workDir}/BO704/ppi_data/"${scan}[$d]" \
		BO705	A	UBO		${workDir}/BO705/ppi_data/"${scan}[$a]" \
		BO705	A	FBO		${workDir}/BO705/ppi_data/"${scan}[$b]" \
		BO705	A	CA		${workDir}/BO705/ppi_data/"${scan}[$c]" \
		BO705	A	MASK	${workDir}/BO705/ppi_data/"${scan}[$d]" \
		BO706	A	UBO		${workDir}/BO706/ppi_data/"${scan}[$a]" \
		BO706	A	FBO		${workDir}/BO706/ppi_data/"${scan}[$b]" \
		BO706	A	CA		${workDir}/BO706/ppi_data/"${scan}[$c]" \
		BO706	A	MASK	${workDir}/BO706/ppi_data/"${scan}[$d]" \
		BO708	A	UBO		${workDir}/BO708/ppi_data/"${scan}[$a]" \
		BO708	A	FBO		${workDir}/BO708/ppi_data/"${scan}[$b]" \
		BO708	A	CA		${workDir}/BO708/ppi_data/"${scan}[$c]" \
		BO708	A	MASK	${workDir}/BO708/ppi_data/"${scan}[$d]" \
		BO709	A	UBO		${workDir}/BO709/ppi_data/"${scan}[$a]" \
		BO709	A	FBO		${workDir}/BO709/ppi_data/"${scan}[$b]" \
		BO709	A	CA		${workDir}/BO709/ppi_data/"${scan}[$c]" \
		BO709	A	MASK	${workDir}/BO709/ppi_data/"${scan}[$d]" \
		BO710	A	UBO		${workDir}/BO710/ppi_data/"${scan}[$a]" \
		BO710	A	FBO		${workDir}/BO710/ppi_data/"${scan}[$b]" \
		BO710	A	CA		${workDir}/BO710/ppi_data/"${scan}[$c]" \
		BO710	A	MASK	${workDir}/BO710/ppi_data/"${scan}[$d]" \
		BO712	A	UBO		${workDir}/BO712/ppi_data/"${scan}[$a]" \
		BO712	A	FBO		${workDir}/BO712/ppi_data/"${scan}[$b]" \
		BO712	A	CA		${workDir}/BO712/ppi_data/"${scan}[$c]" \
		BO712	A	MASK	${workDir}/BO712/ppi_data/"${scan}[$d]" \
		BO915	A	UBO		${workDir}/BO915/ppi_data/"${scan}[$a]" \
		BO915	A	FBO		${workDir}/BO915/ppi_data/"${scan}[$b]" \
		BO915	A	CA		${workDir}/BO915/ppi_data/"${scan}[$c]" \
		BO915	A	MASK	${workDir}/BO915/ppi_data/"${scan}[$d]" \
		BO930	A	UBO		${workDir}/BO930/ppi_data/"${scan}[$a]" \
		BO930	A	FBO		${workDir}/BO930/ppi_data/"${scan}[$b]" \
		BO930	A	CA		${workDir}/BO930/ppi_data/"${scan}[$c]" \
		BO930	A	MASK	${workDir}/BO930/ppi_data/"${scan}[$d]" \
		BO976	A	UBO		${workDir}/BO976/ppi_data/"${scan}[$a]" \
		BO976	A	FBO		${workDir}/BO976/ppi_data/"${scan}[$b]" \
		BO976	A	CA		${workDir}/BO976/ppi_data/"${scan}[$c]" \
		BO976	A	MASK	${workDir}/BO976/ppi_data/"${scan}[$d]" \
		BO999	A	UBO		${workDir}/BO999/ppi_data/"${scan}[$a]" \
		BO999	A	FBO		${workDir}/BO999/ppi_data/"${scan}[$b]" \
		BO999	A	CA		${workDir}/BO999/ppi_data/"${scan}[$c]" \
		BO999	A	MASK	${workDir}/BO999/ppi_data/"${scan}[$d]"

 	fi
done







