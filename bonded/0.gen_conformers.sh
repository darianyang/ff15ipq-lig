#!/bin/bash
# RUN AS: $ bash 0.gen_conformers.sh
# generate conformations and calculate SPE of PDB.pdb

###########################################################
####################### VARIABLES #########################
###########################################################
# arbitrary name of the iteration directory
ITERATION=v00
# 3 letter restype identifier for your molecule
PDB=mon
# name of the library file with vacuum phase atomic charges
LIB_VAC=mon_gaff_02_vac.lib
# name of the frcmod file from gaff and charges directory
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

mkdir $ITERATION
cd $ITERATION &&

# 1) make directory for each res class and create vac top and crd files
cat << EOF > tleap_vacuo.in
source leaprc.gaff
loadoff ../$LIB_VAC
loadAmberParams ../$FRCMOD
${PDB} = loadpdb ../${PDB}.pdb
check ${PDB}
set ${PDB} box {32.006 32.006 32.006}
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
  -o    GenConformers.out
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
#
#mkdir CONFS_OOUT
#
## 3) run orca single-point energy calcs in vacuo for each conformation
#cat << EOF > ${PDB}_RUN_ORCA.slurm
##!/bin/bash
##SBATCH --job-name=${PDB}_${ITERATION}_SPE_CALC
##SBATCH --cluster=smp
##SBATCH --partition=smp
##SBATCH --nodes=1
##SBATCH --ntasks-per-node=$CPUS
##SBATCH --mem=16g
##SBATCH --time=144:00:00  
##SBATCH --mail-user=dty7@pitt.edu
##SBATCH --mail-type=END,FAIL
##SBATCH --output=slurm_spe.out
##SBATCH --error=slurm_spe.err
#
## load ORCA and prereqs
#module load gcc/4.8.5
#module load openmpi/4.1.1
#module load orca/5.0.0
#
## echo commands to stdout
#set -x 
#
#NJOB=0
#for I in {1..${N_CONFS}} ; do
#    orca CONFS/Conf\${I}.orca > CONFS_OOUT/Conf\${I}.oout &
#    let "NJOB+=1"
#    if [ \${NJOB} -eq ${CPUS} ] ; then
#        NJOB=0
#        wait
#    fi
#done
#
## finish any unevenly ran jobs
#wait
#
## run EXTRACT ENERGIES script
#mdgx -i ${PDB}_concat.mdgx -O &&
#
## gives stats of job, wall time, etc.
#crc-job-stats.py 
#EOF
# 
## 4) write file to extract the energies from each conformation SPE QM calc
#cat << EOF > ${PDB}_concat.mdgx
#&files
#  -p      ${PDB}_V.top
#  -o      concat.out
#  -d      energies.dat
#  -x      concat_coords.cdf
#&end
#
#&speval
#  data    CONFS_OOUT/Conf*.oout
#&end
#EOF
#
#sbatch ${PDB}_RUN_ORCA.slurm
#echo -e "FINISHED $N_CONFS CONFSGEN AND SPE CALC SUBMISSION FOR $PDB ITER:$ITERATION \n"
#cd ..

