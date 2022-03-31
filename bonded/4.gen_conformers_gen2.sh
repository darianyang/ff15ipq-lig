#!/bin/bash
# RUN AS: $ bash 4.gen_conformers_gen2.sh
# generate conformations of PDB.pdb
# the only difference now is that there is an energy convergence
# criterion implemented in the mdgx &configs module

###########################################################
####################### VARIABLES #########################
###########################################################
# arbitrary name of the iteration directory
ITERATION=v00
# 3 letter restype identifier for your molecule
PDB=mon
# name of the library file with vacuum phase atomic charges
LIB_VAC=mon_gaff_02_vac.lib
# name of the NEW frcmod file from gen 1 fitting
FRCMOD=FIT_${ITERATION}.frcmod

###########################################################
# NOTE: you must fill out the &configs settings for       #
#       sampling your desired molecule conformations      #
#       See (2) under &configs - line 59                  #
###########################################################
###########################################################
###########################################################

mkdir $ITERATION
cd $ITERATION &&

# 1) make directory for each res class and create vac top and crd files
cat << EOF > tleap_vacuo_G2.in
source leaprc.gaff
loadoff ../$LIB_VAC
loadAmberParams $FRCMOD
${PDB} = loadpdb ../${PDB}.pdb
check ${PDB}
setBox ${PDB} vdw 12.0
#set ${PDB} box {32.006 32.006 32.006}
saveAmberParm ${PDB} ${PDB}_V_G2.top ${PDB}_V_G2.crd
savepdb ${PDB} ${PDB}_V_G2.pdb
quit
EOF

tleap -f tleap_vacuo_G2.in > tleap_vacuo_G2.out &&
echo -e "\nFinished creating in vacuo $PDB G2 file."

mkdir G2_CONFS
cd G2_CONFS &&

# 2) run mdgx to generate 1000 conformations and orca input for each res class
cat << EOF > ${PDB}_GEN_CONFS_G2.mdgx
&files
  -p    ../${PDB}_V_G2.top
  -c    ../concat_coords.cdf
  -o    ../GenConformers_G2.out
&end

&configs
  verbose 1

  % Cull results at a tight energy convergence criterion
  % The settings above will cull structures if their molecular mechanics energies 
  % (according to the input force field, here GAFF, plus our fitted charges and 
  % first pass bonded parameters) differ by less than 0.01 kcal/mol
  simEtol   0.01,

  % Controls on the quantum mechanical operations
  qmlev    'RI-MP2',
  basis    'cc-pVTZ cc-pVTZ/c',

  % Calc settings
  ncpu '1'
  maxcore '4096'

  % Output controls: TAKE NOTE, this will generate a lot of files so
  % do this in a clean directory that you won't ls very often.
  outbase  'Conf', 'Conf'
  write    'pdb',  'orca'
  outsuff  'pdb',  'orca'
&end
EOF

mdgx -i ${PDB}_GEN_CONFS_G2.mdgx -O
echo -e "Finished generating ${N_CONFS} conformations of ${PDB}."

