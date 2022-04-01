#!/bin/bash
# RUN AS: $ bash 8.prep_next_iter.sh
# set up the next iteration directory and files

#####################################################################
########################### Set Variables ###########################
#####################################################################
# this should be your 3 letter PDB residue name
PDB=mon
# this is the $ITERATION variable from the previous run
PREV_ITER=v00
# put your desired $ITERATION variable for the next run
NEXT_ITER=v01
# set this to true if you ran gen2 scripts
GEN2=true
#GEN2=false
#####################################################################
#####################################################################
#####################################################################

# make new iteration directory
mkdir -v $NEXT_ITER

# copy the finished frcmod files to main and next_iter directories
cp -v $PREV_ITER/FIT_${PREV_ITER}.frcmod ${PDB}_${PREV_ITER}.frcmod
cp -v $PREV_ITER/FIT_${PREV_ITER}.frcmod $NEXT_ITER/${PDB}.frcmod
if [ "$GEN2" = true ] ; then
    cp -v $PREV_ITER/FIT_${PREV_ITER}_G2.frcmod ${PDB}_${PREV_ITER}_G2.frcmod
    cp -v $PREV_ITER/FIT_${PREV_ITER}_G2.frcmod $NEXT_ITER/${PDB}.frcmod
fi

# change the iteration variables to new values
# need extented ('') sed for MacOSX (sed -i '' "s//" file)
sed -i "s/ITERATION=$PREV_ITER/ITERATION=$NEXT_ITER/" *.sh
