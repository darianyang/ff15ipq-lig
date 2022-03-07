#!/bin/bash
# run_extract_energies.sh

ITER=V00
RES_CLASSES=(W4F W5F W6F W7F Y3F YDF F4F FTF)

cd $ITER &&

for RES in ${RES_CLASSES[@]} ; do
 
    cd $RES &&
    # run EXTRACT ENERGIES script
    mdgx -i ${RES}_concat.mdgx -O
    cd ..

done
