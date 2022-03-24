#!/bin/bash
# set up the next iteration directory and files

#####################################################################
########################### Set Variables ###########################
#####################################################################
# this should be your 3 letter PDB residue name
PDB=mon   
# this is the $ITERATION variable from the previous run
PREV_ITER=gaff_02
# put your desired $ITERATION variable for the next run
NEXT_ITER=gaff_03
# optional variable to check the mol2 charges in chimerax
CHECK=false
#####################################################################
#####################################################################
#####################################################################

# make new iteration directory and populate it
mkdir -v $NEXT_ITER
cp -v $PREV_ITER/${PDB}.frcmod $NEXT_ITER/

# name of the new lib file from previous iteration
# you can set this yourself or just keep this default behavior
LIB=${PDB}_${PREV_ITER}.lib 

# rename the new library file from script 3.1 and copy into new iteration
if [ -f NEW_LIB_FILE.lib ] ; then
    mv -v NEW_LIB_FILE.lib $LIB
fi
cp -v $LIB $NEXT_ITER/${PDB}.lib 

# change the iteration variables to new values
# need extented ('') sed for MacOSX (sed -i '' "s//" file)
sed -i "s/ITERATION=$PREV_ITER/ITERATION=$NEXT_ITER/" 1.0.ipq_gen_conf_highT_equil.slurm
sed -i "s/ITERATION=$PREV_ITER/ITERATION=$NEXT_ITER/" 1.0.ipq_gen_conf_mdgx_equil.slurm
sed -i "s/ITERATION=$PREV_ITER/ITERATION=$NEXT_ITER/" 1.5.visualize_confs.sh
sed -i "s/ITERATION = '$PREV_ITER'/ITERATION = '$NEXT_ITER'/" 1.6.conformer_matrix.py
sed -i "s/ITERATION=$PREV_ITER/ITERATION=$NEXT_ITER/" 2.0.ipq_qm_multi_conf_run.sh
sed -i "s/ITERATION=$PREV_ITER/ITERATION=$NEXT_ITER/" 2.5.check_completion.sh
sed -i "s/ITERATION=$PREV_ITER/ITERATION=$NEXT_ITER/" 3.0.resp_fitting.sh

# make a pdb file and a mol2 file with updated charges for NEXT_ITER
cat << EOF > $NEXT_ITER/tleap_mol2.in
source leaprc.gaff
loadoff $NEXT_ITER/${PDB}.lib
loadAmberParams $NEXT_ITER/${PDB}.frcmod
${PDB}P = loadmol2 $PREV_ITER/${PDB}.mol2
savepdb ${PDB}P $NEXT_ITER/${PDB}.pdb
${PDB}N = loadpdb $NEXT_ITER/${PDB}.pdb
# save mol2 using ff dependent atom types in col 6
savemol2 ${PDB}N $NEXT_ITER/${PDB}.mol2 1
quit
EOF

tleap -f $NEXT_ITER/tleap_mol2.in > $NEXT_ITER/tleap_mol2.out

echo -e "\n\tThe next iteration directory is ready to go and scripts 1-3 are updated!"
echo -e "\tYou should be able to just run scripts 1-3 as is, but check them just in case.\n"

echo -e "If your mol2 file dosen't have the appropritate atom types or charges, you may need"
echo -e "to make sure the UNIT naming in the library file and the restype naming in the"
echo -e "PDB and MOL2 files are all consistent, i.e if your PDB restype is MON (for monastrol)"
echo -e "the MOL2 restype should be MON and all UNIT entries in the library file are MON.\n"

# at this point I like to check the new charges in chimerax
if [ $CHECK = "true" ] ; then
    CMD="open $NEXT_ITER/${PDB}.mol2 \n"
    CMD="$CMD color byattribute charge range -1,1"
    echo -e "$CMD" > mol2view.cxc
    chimerax mol2view.cxc
    rm mol2view.cxc
fi
