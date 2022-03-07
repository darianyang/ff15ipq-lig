#!/bin/bash
# RUN AS: $ bash scripts/0.resubmit.sh
# resubmit failed or incomplete runs for SPE calculations of each RES_CLASS

# load env
source ~/.setup.sh

CPUS=24
N_CONFS=1000

ITER=V00
LIB_VAC=19F_FF15IPQ_V03_VAC.lib
FRCMOD=19F_FF15IPQ_V00.frcmod

RES_CLASSES=(W4F W5F W6F W7F Y3F YDF F4F FTF)

mkdir $ITER
cd $ITER &&

###############################################################################
#######################       BEGIN LOOP         ##############################
###############################################################################
for RES in ${RES_CLASSES[@]} ; do

cd $RES &&

# run orca single-point energy calcs in vacuo for each conformation
cat << EOF > ${RES}_RUN_ORCA.slurm
#!/bin/bash
#SBATCH --job-name=${RES}_${ITER}_SPE_CALC
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=$CPUS
#SBATCH --mem=16g
#SBATCH --time=143:59:59  
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
echo "\$(date)" >> skip.log
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
mdgx -i ${RES}_concat.mdgx -O

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

done
###############################################################################
#######################         END LOOP         ##############################
###############################################################################
