#!/bin/bash
# set up the next iteration directory and files

PDB=mon             # this should be your 3 letter PDB residue name
PREV_ITER=gaff_00   # this is the $ITERATION variable from the previous run
NEXT_ITER=gaff_01   # put your desired $ITERATION variable for the next run

LIB=${PDB}_${PREV_ITER}.lib     # name of the new lib file from previous iteration

# rename the new library file from script 3.1 and copy into new iteration
if [ -f NEW_LIB_FILE.lib ] ; then
    mv -v NEW_LIB_FILE.lib $LIB
fi
cp -v $LIB $NEXT_ITER/${PDB}.lib 

# make new iteration directory and populate it
mkdir -v $NEXT_ITER
cp -v $PREV_ITER/{${PDB}.pdb,${PDB}.frcmod} $NEXT_ITER/


