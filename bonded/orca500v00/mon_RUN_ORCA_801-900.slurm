#!/bin/bash
#SBATCH --job-name=mon_v00_SPE_CALC_801_900
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --mem=16g
#SBATCH --time=23:59:59  
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
echo "$(date)" >> skip_801-900.log
for I in {801..900} ; do

    # skip confs where SPE calculations are completed
    CONF_OOUT=$(tail -1 CONFS_OOUT/Conf${I}.oout)
    if [[ "$CONF_OOUT" == "TOTAL RUN TIME:"* ]] ; then
        echo "FOR PDB = mon : ITERATION = v00 : CONF = $I : RUN COMPLETED: SKIPPING" >> skip_801-900.log
        let "SKIP+=1"
        continue
    fi

    orca CONFS/Conf${I}.orca > CONFS_OOUT/Conf${I}.oout &
    let "NJOB+=1"

    if [ ${NJOB} -eq 20 ] ; then
        NJOB=0
        wait
    fi

done

echo -e "\nTOTAL SKIPPED CONFORMATIONS = ${SKIP}" >> skip_801-900.log

# finish any unevenly ran jobs
wait

# run EXTRACT ENERGIES script
mdgx -i mon_concat.mdgx -O

# gives stats of job, wall time, etc.
crc-job-stats.py 
