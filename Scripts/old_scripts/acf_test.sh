#!/bin/bash


workDir=/Volumes/Yorick/Nate_work/AutismOlfactory
ppiDir=${workDir}/Analyses/ppiAnalysis
refDir=${workDir}/BO1048/ppi_data
mask=${ppiDir}/Template_GM_mask+tlrc


cd $refDir

c=0; for i in ZTrans_Indiv*tlrc.HEAD; do
    ziList[$c]=${i%.*}
    let c=$[$c+1]
done


cd $ppiDir

for i in ${ziList[0]}; do

    scan=$i
	tmp=${i%+*}
	out=666_${tmp#*_}


    if [ ! -f ${out}+tlrc.HEAD ]; then

        3dttest++ -prefix $out \
        -mask $mask \
        -resid 666_resid \
        -ACF \
        -Clustsim \
        -setA Con \
        BO1048	${workDir}/BO1048/ppi_data/"${scan}" \
		BO1055	${workDir}/BO1055/ppi_data/"${scan}" \
		BO1063	${workDir}/BO1063/ppi_data/"${scan}" \
		BO1065	${workDir}/BO1065/ppi_data/"${scan}" \
		BO1086	${workDir}/BO1086/ppi_data/"${scan}" \
		BO1104	${workDir}/BO1104/ppi_data/"${scan}" \
		BO1108	${workDir}/BO1108/ppi_data/"${scan}" \
		BO1109	${workDir}/BO1109/ppi_data/"${scan}" \
		BO1113	${workDir}/BO1113/ppi_data/"${scan}" \
		BO1115	${workDir}/BO1115/ppi_data/"${scan}" \
		BO1116	${workDir}/BO1116/ppi_data/"${scan}" \
		BO1117	${workDir}/BO1117/ppi_data/"${scan}" \
		BO1118	${workDir}/BO1118/ppi_data/"${scan}" \
		BO1119	${workDir}/BO1119/ppi_data/"${scan}" \
		BO1120	${workDir}/BO1120/ppi_data/"${scan}" \
		BO1121	${workDir}/BO1121/ppi_data/"${scan}" \
		BO1126	${workDir}/BO1126/ppi_data/"${scan}" \
		BO1127	${workDir}/BO1127/ppi_data/"${scan}" \
		BO1128	${workDir}/BO1128/ppi_data/"${scan}" \
		BO1130	${workDir}/BO1130/ppi_data/"${scan}" \
		BO1131	${workDir}/BO1131/ppi_data/"${scan}" \
		BO1133	${workDir}/BO1133/ppi_data/"${scan}" \
		BO1134	${workDir}/BO1134/ppi_data/"${scan}" \
		BO1135	${workDir}/BO1135/ppi_data/"${scan}" \
		BO1137	${workDir}/BO1137/ppi_data/"${scan}" \
		BO1138	${workDir}/BO1138/ppi_data/"${scan}" \
		BO1140	${workDir}/BO1140/ppi_data/"${scan}" \
		-setB Aut \
		BO606	${workDir}/BO606/ppi_data/"${scan}" \
		BO608	${workDir}/BO608/ppi_data/"${scan}" \
		BO618	${workDir}/BO618/ppi_data/"${scan}" \
		BO625	${workDir}/BO625/ppi_data/"${scan}" \
		BO632	${workDir}/BO632/ppi_data/"${scan}" \
		BO670	${workDir}/BO670/ppi_data/"${scan}" \
		BO674	${workDir}/BO674/ppi_data/"${scan}" \
		BO676	${workDir}/BO676/ppi_data/"${scan}" \
		BO683	${workDir}/BO683/ppi_data/"${scan}" \
		BO694	${workDir}/BO694/ppi_data/"${scan}" \
		BO695	${workDir}/BO695/ppi_data/"${scan}" \
		BO696	${workDir}/BO696/ppi_data/"${scan}" \
		BO698	${workDir}/BO698/ppi_data/"${scan}" \
		BO699	${workDir}/BO699/ppi_data/"${scan}" \
		BO700	${workDir}/BO700/ppi_data/"${scan}" \
		BO701	${workDir}/BO701/ppi_data/"${scan}" \
		BO703	${workDir}/BO703/ppi_data/"${scan}" \
		BO704	${workDir}/BO704/ppi_data/"${scan}" \
		BO705	${workDir}/BO705/ppi_data/"${scan}" \
		BO706	${workDir}/BO706/ppi_data/"${scan}" \
		BO708	${workDir}/BO708/ppi_data/"${scan}" \
		BO709	${workDir}/BO709/ppi_data/"${scan}" \
		BO710	${workDir}/BO710/ppi_data/"${scan}" \
		BO712	${workDir}/BO712/ppi_data/"${scan}" \
		BO915	${workDir}/BO915/ppi_data/"${scan}" \
		BO930	${workDir}/BO930/ppi_data/"${scan}" \
		BO976	${workDir}/BO976/ppi_data/"${scan}" \
		BO999	${workDir}/BO999/ppi_data/"${scan}"
	fi
done
