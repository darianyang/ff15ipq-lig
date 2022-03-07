#!/bin/bash
# extract_outliers.sh
# extract the outlier conformations at 4 sigma for each residue and remove

ITER=V00
#RES_CLASSES=(W4F W5F W6F W7F Y3F YDF F4F FTF)
RES_CLASSES=(W5F)
OUT=FIT_V00_GEN2.out

cd $ITER &&

for RES in ${RES_CLASSES[@]} ; do 

    echo -e "\nRUNNING: $RES"
    OUTLIERS=0
    mkdir -p $RES/OUTLIERS

    for LINE in $(grep "$RES/concat_coords.cdf" $OUT | awk '{print $3}') ; do
        re='^[0-9]+$'
        if [[ "$LINE" =~ $re ]] ; then 
            #echo "Moving CONF:$LINE for $RES"
            mv -v $RES/CONFS_OOUT/Conf${LINE}.oout $RES/OUTLIERS
            let "OUTLIERS++"
        fi
    done

    echo "Finished moving $OUTLIERS outliers for $RES"

done
