#!/bin/bash
# RUN AS: $ bash scripts/2.iterate_gen2.sh
# generate conformations and calculate SPE of each RES_CLASS

# load env
source ~/.setup.sh

CPUS=8
N_CONFS=1000

ITER=V01
LIB_VAC=19F_FF15IPQ_V03_VAC.lib
FRCMOD=19F_FF15IPQ_FIT_V01.frcmod

RES_CLASSES=(W4F W5F W6F W7F Y3F YDF F4F FTF)
#RES_CLASSES=(W4F)

cd $ITER &&

###############################################################################
#######################       BEGIN LOOP         ##############################
###############################################################################
for RES in ${RES_CLASSES[@]} ; do


# 1) make directory for each res class and create vac top and crd files
cd $RES &&
cat << EOF > tleap_vacuo_gen2.in
source leaprc.protein.ff15ipq
loadoff ../../$LIB_VAC
loadAmberParams ../../$FRCMOD
${RES} = sequence { ACE ${RES} NME }
check ${RES}
set ${RES} box {32.006 32.006 32.006}
saveAmberParm ${RES} ${RES}_V_GEN2.top ${RES}_V_GEN2.crd
savepdb ${RES} ${RES}_V_GEN2.pdb
quit
EOF

tleap -f tleap_vacuo_gen2.in > tleap_vacuo_gen2.out &&
echo -e "\nFinished creating in vacuo $RES file."

# set RES_CLASS dependent phi psi angle definitions
if [ $RES = "W4F" ] || [ $RES = "W5F" ] || [ $RES = "W6F" ] || [ $RES = "W7F" ] ; then
    PHI=(5 7 9 29)
    PSI=(7 9 29 31)
elif [ $RES = "Y3F" ] || [ $RES = "YDF" ] ; then
    PHI=(5 7 9 26)
    PSI=(7 9 26 28)
elif [ $RES = "F4F" ] ; then
    PHI=(5 7 9 25)
    PSI=(7 9 25 27)
elif [ $RES = "FTF" ] ; then
    PHI=(5 7 9 28)
    PSI=(7 9 28 30)
fi

rm -r GEN2_CONFS
mkdir GEN2_CONFS
cd GEN2_CONFS &&

# 2) run mdgx to generate 1000 conformations and orca input for each res class
cat << EOF > ${RES}_GEN_CONFS_GEN2.mdgx
&files
  -p    ../${RES}_V_GEN2.top
  -c    ../concat_coords.cdf
  -o    RegenConformers.out
&end

&configs
  verbose 1

  % Cull results at a tight energy convergence criterion
  simEtol   0.01,

  % Controls on the quantum mechanical operations
  qmlev    'MP2',
  basis    'cc-pvTZ',

  % Calc settings
  ncpu '1'
  maxcore '4096'

  % Output controls
  outbase  'Conf', 'Conf'
  write    'pdb',  'orca'
  outsuff  'pdb',  'orca'
&end
EOF

mdgx -i ${RES}_GEN_CONFS_GEN2.mdgx -O
echo -e "Finished generating ${N_CONFS} conformations of ${RES}."

# return to main $RES dir
cd .. &&

# make ramachandran plot
cat << EOF > RAMA_GEN2.sh
#!/bin/bash
echo "#$RES $ITER PHI PSI Angles" > rama_gen2.dat
for i in {1..${N_CONFS}}; do
  if [ ! -f GEN2_CONFS/Conf\${i}.pdb ] ; then
    continue
  fi
  COMMAND="           parm ${RES}_V.top \n"
  COMMAND="\${COMMAND} trajin GEN2_CONFS/Conf\${i}.pdb \n"
  COMMAND="\${COMMAND} dihedral phi @${PHI[0]} @${PHI[1]} @${PHI[2]}  @${PHI[3]} out phipsi.dat \n"
  COMMAND="\${COMMAND} dihedral psi @${PSI[0]} @${PSI[1]} @${PSI[2]}  @${PSI[3]} out phipsi.dat \n"
  COMMAND="\${COMMAND} go"
  echo -e \${COMMAND} | cpptraj >> cpp_rama_gen2.out
  cat phipsi.dat | tail -n +2 >> rama_gen2.dat
done

python ../../scripts/plot_rama.py

rm phipsi.dat
EOF

bash RAMA_GEN2.sh &&
echo -e "Finished generating Ramachandran plot for ${RES}."

mkdir GEN2_CONFS_OOUT

# 3) run orca single-point energy calcs in vacuo for each conformation
cat << EOF > ${RES}_RUN_ORCA_GEN2.slurm
#!/bin/bash
#SBATCH --job-name=${RES}_${ITER}_SPE_CALC_GEN2
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=$CPUS
#SBATCH --mem=16g
#SBATCH --time=72:00:00  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=slurm_spe_gen2.out
#SBATCH --error=slurm_spe_gen2.err

# load ORCA and prereqs
module load openmpi/3.1.4
module load orca/4.2.0

# echo commands to stdout
set -x 

NJOB=0
for I in {1..${N_CONFS}} ; do

  if [ ! -f GEN2_CONFS/Conf\${I}.pdb ] ; then
    continue
  fi

  orca GEN2_CONFS/Conf\${I}.orca > GEN2_CONFS_OOUT/Conf\${I}.oout &
  let "NJOB+=1"
  if [ \${NJOB} -eq ${CPUS} ] ; then
    NJOB=0
    wait
  fi

done

# finish any unevenly ran jobs
wait

# run EXTRACT ENERGIES script
mdgx -i ${RES}_concat_gen2.mdgx -O &&

# gives stats of job, wall time, etc.
crc-job-stats.py 
EOF
 
# 4) extract the energies from each conformation SPE QM calc
cat << EOF > ${RES}_concat_gen2.mdgx
&files
  -p      ${RES}_V_GEN2.top
  -o      concat_gen2.out
  -d      energies_gen2.dat
  -x      concat_coords_gen2.cdf
&end

&speval
  data    GEN2_CONFS_OOUT/Conf*.oout
&end
EOF

sbatch ${RES}_RUN_ORCA_GEN2.slurm
echo -e "FINISHED GEN2 $N_CONFS CONFSGEN AND SPE CALC SUBMISSION FOR $RES ITER:$ITER \n"
cd ..

done
###############################################################################
#######################         END LOOP         ##############################
###############################################################################
