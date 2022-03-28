#!/bin/bash
# RUN AS: $ bash 1.resubmit.sh
# submit new or resubmit failed or incomplete runs for SPE calculations

###########################################################
####################### VARIABLES #########################
###########################################################
# CPUs per node to use for the slurm script
CPUS=24
# number of conformations to generate
N_CONFS=1000
# arbitrary name of the iteration directory
ITERATION=v00
# 3 letter restype identifier for your molecule
PDB=mon
###########################################################
###########################################################
###########################################################

mkdir $ITERATION
cd $ITERATION &&

# run orca single-point energy calcs in vacuo for each conformation
cat << EOF > ${PDB}_RUN_ORCA.slurm
#!/bin/bash
#SBATCH --job-name=${PDB}_${ITERATION}_SPE_CALC
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
module load gcc/4.8.5
module load openmpi/4.1.1
module load orca/5.0.0

# echo commands to stdout
set -x 

NJOB=0
SKIP=0
echo "\$(date)" >> skip.log
for I in {1..${N_CONFS}} ; do

    # skip confs where SPE calculations are completed
    CONF_OOUT=\$(tail -1 CONFS_OOUT/Conf\${I}.oout)
    if [[ "\$CONF_OOUT" == "TOTAL RUN TIME:"* ]] ; then
        echo "FOR PDB = $PDB : ITERATION = $ITERATION : CONF = \$I : RUN COMPLETED: SKIPPING" >> skip.log
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
mdgx -i ${PDB}_concat.mdgx -O

# gives stats of job, wall time, etc.
crc-job-stats.py 
EOF
 
# 4) extract the energies from each conformation SPE QM calc
cat << EOF > ${PDB}_concat.mdgx
&files
  -p      ${PDB}_V.top
  -o      concat.out
  -d      energies.dat
  -x      concat_coords.cdf
&end

&speval
  data    CONFS_OOUT/Conf*.oout
&end
EOF

sbatch ${PDB}_RUN_ORCA.slurm
echo -e "FINISHED $N_CONFS CONFSGEN AND SPE CALC SUBMISSION FOR $PDB ITERATION:$ITERATION \n"

