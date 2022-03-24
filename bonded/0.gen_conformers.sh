#!/bin/bash
# RUN AS: $ bash scripts/0.gen_conformers.sh
# generate conformations and calculate SPE of each RES_CLASS

# load env
source ~/.setup.sh

CPUS=32
N_CONFS=1000

ITER=V01
LIB_VAC=19F_FF15IPQ_V03_VAC.lib
FRCMOD=19F_FF15IPQ_FIT_V00_GEN2.frcmod

mkdir $ITER
cd $ITER &&


# 1) make directory for each res class and create vac top and crd files
cat << EOF > tleap_vacuo.in
source leaprc.protein.ff15ipq
loadoff ../../$LIB_VAC
loadAmberParams ../../$FRCMOD
${RES} = sequence { ACE ${RES} NME }
check ${RES}
set ${RES} box {32.006 32.006 32.006}
saveAmberParm ${RES} ${RES}_V.top ${RES}_V.crd
savepdb ${RES} ${RES}_V.pdb
quit
EOF

tleap -f tleap_vacuo.in > tleap_vacuo.out &&
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

mkdir CONFS
cd CONFS &&

# 2) run mdgx to generate 1000 conformations and orca input for each res class
cat << EOF > ${RES}_GEN_CONFS.mdgx
&files
  -p    ../${RES}_V.top
  -c    ../${RES}_V.crd
  -o    GenConformers.out
&end

&configs
  GridSample    @${PHI[0]} @${PHI[1]} @${PHI[2]}  @${PHI[3]}    { -180.0 180.0 }  Krst 32.0
  GridSample    @${PSI[0]} @${PSI[1]} @${PSI[2]}  @${PSI[3]}    { -180.0 180.0 }  Krst 32.0
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

mdgx -i ${RES}_GEN_CONFS.mdgx -O
echo -e "Finished generating ${N_CONFS} conformations of ${RES}."

# make ramachandran plot
cat << EOF > RAMA.sh
#!/bin/bash
echo "#$RES $ITER PHI PSI Angles" > rama.dat
for i in {1..${N_CONFS}}; do
  COMMAND="           parm ${RES}_V.top \n"
  COMMAND="\${COMMAND} trajin CONFS/Conf\${i}.pdb \n"
  COMMAND="\${COMMAND} dihedral phi @${PHI[0]} @${PHI[1]} @${PHI[2]}  @${PHI[3]} out phipsi.dat \n"
  COMMAND="\${COMMAND} dihedral psi @${PSI[0]} @${PSI[1]} @${PSI[2]}  @${PSI[3]} out phipsi.dat \n"
  COMMAND="\${COMMAND} go"
  echo -e \${COMMAND} | cpptraj >> cpp_rama.out
  cat phipsi.dat | tail -n +2 >> rama.dat
done

python ../../scripts/plot_rama.py

rm phipsi.dat
EOF

bash RAMA.sh &&
echo -e "Finished generating Ramachandran plot for ${RES}."

mkdir CONFS_OOUT

# 3) run orca single-point energy calcs in vacuo for each conformation
cat << EOF > ${RES}_RUN_ORCA.slurm
#!/bin/bash
#SBATCH --job-name=${RES}_${ITER}_SPE_CALC
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=$CPUS
#SBATCH --mem=16g
#SBATCH --time=144:00:00  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=slurm_spe.out
#SBATCH --error=slurm_spe.err

# load ORCA and prereqs
module load openmpi/3.1.4
module load orca/4.2.0

# echo commands to stdout
set -x 

NJOB=0
SKIP=0
for I in {1..${N_CONFS}} ; do

    # skip confs where SPE calculations are completed
    CONF_OOUT=\$(tail -1 CONFS_OOUT/Conf\${I}.oout)
    if [[ "\$CONF_OOUT" == "TOTAL RUN TIME:"* ]] ; then
        echo "FOR RES = $RES : ITER = $ITER : CONF = \$I : RUN COMPLETED: SKIPPING" >> skip.log
        let "SKIP+=1"
        continue
    fi

  orca CONFS/Conf\${I}.orca > CONFS_OOUT/Conf\${I}.oout &
  let "NJOB+=1"
  if [ \${NJOB} -eq ${CPUS} ] ; then
    NJOB=0
    wait
  fi
done

echo -e "\nTOTAL SKIPPED CONFORMATIONS = \${SKIP}" >> skip.log

# finish any unevenly ran jobs
wait

# run EXTRACT ENERGIES script
mdgx -i ${RES}_concat.mdgx -O &&

# gives stats of job, wall time, etc.
crc-job-stats.py 
EOF
 
# 4) extract the energies from each conformation SPE QM calc
cat << EOF > ${RES}_concat.mdgx
&files
  -p      ${RES}_V.top
  -o      concat.out
  -d      energies.dat
  -x      concat_coords.cdf
&end

&speval
  data    CONFS_OOUT/Conf*.oout
&end
EOF

sbatch ${RES}_RUN_ORCA.slurm
echo -e "FINISHED $N_CONFS CONFSGEN AND SPE CALC SUBMISSION FOR $RES ITER:$ITER \n"
cd ..

