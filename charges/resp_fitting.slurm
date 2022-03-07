#!/bin/bash
#SBATCH --job-name=19F_RESP_ALL
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=24g
#SBATCH --time=4:59:59  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=charge_fit/slurm_resp.out
#SBATCH --error=charge_fit/slurm_resp.err

# load appropriate modules, first purge all modules 
# then load in intel (a prereq for loading in amber) and then amber 
module purge
module load intel/2017.3.196
module load amber/18

# echo commands to stdout
set -x 

mdgx -i charge_fit/19F_RESP_v00.in
