#!/bin/bash
# RUN AS: $ bash 0.gen_conformers.sh
# generate conformations and calculate SPE of PDB.pdb

###########################################################
####################### VARIABLES #########################
###########################################################
# arbitrary name of the iteration directory
ITERATION=v02
# 3 letter restype identifier for your molecule
PDB=mon
# name of the library file with vacuum phase atomic charges
LIB_VAC=mon_gaff_02_vac.lib
# name of the frcmod file
FRCMOD=mon.frcmod
# number of conformations to generate with mdgx
N_CONFS=1000

###########################################################
# NOTE: you must fill out the &configs settings for       #
#       sampling your desired molecule conformations      #
#       See (2) under &configs - line 60                  #
###########################################################
###########################################################
###########################################################

# make and prep iteration directory
if [ ! -d $ITERATION ] ; then
    mkdir $ITERATION
fi
if [ ! -f $ITERATION/$FRCMOD ] ; then
    cp -v $FRCMOD $ITERATION/
fi
cd $ITERATION &&

# 1) make directory for each res class and create vac top and crd files
cat << EOF > tleap_vacuo.in
source leaprc.gaff
loadoff ../$LIB_VAC
loadAmberParams $FRCMOD
${PDB} = loadpdb ../${PDB}.pdb
check ${PDB}
setBox ${PDB} vdw 12.0
saveAmberParm ${PDB} ${PDB}_V.top ${PDB}_V.crd
savepdb ${PDB} ${PDB}_V.pdb
quit
EOF

tleap -f tleap_vacuo.in > tleap_vacuo.out &&
echo -e "\nFinished creating in vacuo $PDB file."

mkdir CONFS
cd CONFS &&

# 2) run mdgx to generate 1000 conformations and orca input for each res class
cat << EOF > ${PDB}_GEN_CONFS.mdgx
&files
  -p    ../${PDB}_V.top
  -c    ../${PDB}_V.crd
  -o    ../GenConformers.out
&end

&configs
  % See the amber manual for more information and examples
  % Here I am sampling on the flexible dihedrals available in monastrol
  % from -180 to 180 degrees using a force constant of 32 kcal/mol
  % To visualize the atom numbers, I like to use Avogadro
  % You can also use VMD but note the indexing is by 0 and not 1
  GridSample    @1  @2  @3  @4  { -180.0 180.0 }    Krst 32.0
  GridSample    @2  @3  @4  @6  { -180.0 180.0 }    Krst 32.0
  combine 1 2
  count ${N_CONFS}
  verbose 1

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

mdgx -i ${PDB}_GEN_CONFS.mdgx -O
echo -e "Finished generating ${N_CONFS} conformations of ${PDB}."


## exit CONFS directory
#cd ..
#
## make ramachandran plot
## TODO: hist of each dihedral?
#cat << EOF > RAMA.sh
##!/bin/bash
#echo "#$PDB $ITERATION PHI PSI Angles" > rama.dat
#for i in {1..${N_CONFS}}; do
#  COMMAND="           parm ${PDB}_V.top \n"
#  COMMAND="\${COMMAND} trajin CONFS/Conf\${i}.pdb \n"
#  COMMAND="\${COMMAND} dihedral phi @${PHI[0]} @${PHI[1]} @${PHI[2]}  @${PHI[3]} out phipsi.dat \n"
#  COMMAND="\${COMMAND} dihedral psi @${PSI[0]} @${PSI[1]} @${PSI[2]}  @${PSI[3]} out phipsi.dat \n"
#  COMMAND="\${COMMAND} go"
#  echo -e \${COMMAND} | cpptraj >> cpp_rama.out
#  cat phipsi.dat | tail -n +2 >> rama.dat
#done
#
#python ../../scripts/plot_rama.py
#
#rm phipsi.dat
#EOF
#
#bash RAMA.sh &&
#echo -e "Finished generating Ramachandran plot for ${PDB}."
