#!/bin/bash
#SBATCH --job-name=c9-mon-ipq-mdgx-grid-gen
#SBATCH --cluster=smp
#SBATCH --partition=high-mem
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --mem=216g
#SBATCH --mem-per-cpu=128g
#SBATCH --time=47:59:59  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=slurm_conf_9.out
#SBATCH --error=slurm_conf_9.err

# load appropriate modules, first purge all modules 
# then load in intel (a prereq for loading in amber) and then amber 
module purge
module load intel/2017.3.196
module load amber/18

# echo commands to stdout
set -x 
echo $PWD
echo "Running Conformation 9"

# script to setup directory for one conformation
# takes 1 arg = Conformation Int
# 2nd arg needed for high T conf gen, also compatible with mdgx conf gen
bash 2.ipq_qm_single_conf_setup.sh 9 mon &&

# run mdgx on one conformation
#mpirun -np 1 mdgx.MPI -i ipq_qm_mp2_grid_gen.mdgx
mdgx -i ipq_qm_mp2_grid_gen.mdgx

# gives stats of job, wall time, etc.
crc-job-stats.py 
