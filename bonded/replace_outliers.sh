#!/bin/bash
# replace_outliers.sh
# replace the outlier conformations at 4 sigma for each residue 

ITER=V00
RES_CLASSES=(W4F W5F W6F W7F Y3F YDF F4F FTF)

cd $ITER &&

for RES in ${RES_CLASSES[@]} ; do 

    echo -e "\nRUNNING: $RES"
    mv -v $RES/OUTLIERS/* $RES/CONFS_OOUT
    echo "Finished replacing $OUTLIERS outliers for $RES"

done
