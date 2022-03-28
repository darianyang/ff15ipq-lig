#!/bin/bash
# RUN AS: $ bash 1.run_spe.sh
# submit new or resubmit failed or incomplete runs for SPE calculations
#   I can't get this to work on multiple nodes, but I instead will run
#   multiple jobs to split up the conformations
#       e.g. run 1-500 and 501-1000 on two slurm submissions

###########################################################
####################### VARIABLES #########################
###########################################################
# CPUs per node to use for the slurm script
CPUS=24
# what range of N_CONFS to run
CONFS_START=1
CONFS_END=1000
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
cat << EOF > ${PDB}_RUN_ORCA_${CONFS_START}-${CONFS_END}.slurm
#!/bin/bash
#SBATCH --job-name=${PDB}_${ITERATION}_SPE_CALC_${CONFS_START}_${CONFS_END}
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
for I in {${CONFS_START}..${CONFS_END}} ; do

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
 
# extract the energies from each conformation SPE QM calc
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

sbatch ${PDB}_RUN_ORCA_${CONFS_START}-${CONFS_END}.slurm
echo -e "FINISHED $CONFS_START to $CONFS_END SPE CALC SUBMISSION FOR $PDB ITERATION:$ITERATION \n"

