#!/bin/bash
#SBATCH --job-name=mon_v00_SPE_CALC_G2_1_1000
#SBATCH --cluster=invest
#SBATCH --partition=lchong
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=5
#SBATCH --mem=16g
#SBATCH --time=23:59:59  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=logs/slurm_spe_1_1000_G2.out
#SBATCH --error=logs/slurm_spe_1_1000_G2.err

# load ORCA and prereqs
# ORCA 5.0.0 isn't compatible with mdgx functions for energy extraction
#module load gcc/4.8.5
#module load openmpi/4.1.1
#module load orca/5.0.0

# need ORCA 4.2.0 for mdgx compatibility
module load openmpi/3.1.4
module load orca/4.2.0

# echo commands to stdout
set -x 

NJOB=0
SKIP=0
echo "$(date)" >> logs/skip_1-1000_G2.log
for I in {1..1000} ; do

    # skip confs where SPE calculations are completed
    CONF_OOUT=$(tail -1 G2_CONFS_OOUT/Conf${I}.oout)
    if [[ "$CONF_OOUT" == "TOTAL RUN TIME:"* ]] ; then
        echo "FOR PDB = mon : ITERATION = v00 : CONF = $I : RUN COMPLETED: SKIPPING" >> logs/skip_1-1000_G2.log
        let "SKIP+=1"
        continue
    fi

    # skip if the initial conformation generation failed
    if [ ! -f G2_CONFS/Conf${I}.pdb ] ; then
        echo "FOR PDB = mon : ITERATION = v00 : CONF = $I : INITIAL CONF NOT GENERATED: SKIPPING" >> logs/skip_1-1000_G2.log
        continue
    fi

    # run orca spe calc
    echo -e "\tFOR PDB = mon : ITERATION = v00 : CONF = $I : RUN NOT COMPLETE: RERUNNING" >> logs/skip_1-1000.log
    orca G2_CONFS/Conf${I}.orca > G2_CONFS_OOUT/Conf${I}.oout &
    let "NJOB+=1"

    # run on multiple CPUs
    if [ ${NJOB} -eq 5 ] ; then
        NJOB=0
        wait
    fi

done

echo -e "\nTOTAL SKIPPED CONFORMATIONS = ${SKIP}\n" >> logs/skip_1-1000_G2.log
echo -e "------------------------------------------\n" >> logs/skip_1-1000_G2.log

# finish any unevenly ran jobs
wait

# gives stats of job, wall time, etc.
crc-job-stats.py 
