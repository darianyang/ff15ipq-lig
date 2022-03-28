#!/bin/bash
#SBATCH --job-name=mon_v00_SPE_CALC
#SBATCH --cluster=invest
#SBATCH --partition=lchong
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --mem=16g
#SBATCH --time=144:00:00
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
for I in {1..2} ; do
    orca CONFS/Conf${I}.orca > CONFS_OOUT/Conf${I}.oout &
    let "NJOB+=1"
    if [ ${NJOB} -eq 2 ] ; then
        NJOB=0
        wait
    fi
done

# finish any unevenly ran jobs
wait

# run EXTRACT ENERGIES script
#mdgx -i mon_concat.mdgx -O &&

# gives stats of job, wall time, etc.
crc-job-stats.py 
