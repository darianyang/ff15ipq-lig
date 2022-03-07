#!/bin/bash
##############################################################
##### for all conformations: QM and grid file generation #####
##############################################################

# use of 2 CPUs seems to be the best
CPU=2
ITERATION=v03
PDB=F4F

# go to conformers directory
cd $ITERATION/GenConformers

# multiple conformations: grid gen -------------------- 
#------------------------------------------------------#
# QM with and without the time-averaged solvent density
for CONF in {1..20}; do

echo "RUNNING RES_CLASS:$PDB CONF:$CONF FOR ITERATION:$ITERATION"

# set up conformation directory
cd Conf${CONF}

# if output files already exist for this dir/conf, skip it
if [[ -f grid_output.solv && -f grid_output.vacu ]]; then
    echo "Conf ${CONF} grid output files already exist."
    cd ../
    continue
fi

# copy over single conformation setup script
cp -v ../../../2.ipq_qm_single_conf_setup.sh .

# make mdgx file and run with sbatch
cat << EOF > conf_${CONF}_mdgx_grid_gen.slurm
#!/bin/bash
#SBATCH --job-name=c${CONF}-${PDB}-ipq-mdgx-grid-gen
#SBATCH --cluster=smp
#SBATCH --partition=high-mem
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=${CPU}
#SBATCH --mem=216g
#SBATCH --time=47:59:59  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=slurm_conf_${CONF}.out
#SBATCH --error=slurm_conf_${CONF}.err

# load appropriate modules, first purge all modules 
# then load in intel (a prereq for loading in amber) and then amber 
module purge
module load intel/2017.3.196
module load amber/18

# echo commands to stdout
set -x 
echo \$PWD
echo "Running Conformation ${CONF}"

# script to setup directory for one conformation
# takes 1 arg = Conformation Int
bash 2.ipq_qm_single_conf_setup.sh ${CONF} &&

# run mdgx on one conformation
mpirun -np ${CPU} mdgx.MPI -i ipq_qm_mp2_grid_gen.mdgx

# gives stats of job, wall time, etc.
crc-job-stats.py 
EOF

sbatch conf_${CONF}_mdgx_grid_gen.slurm 

cd ../
done
#------------------------------------------------------#


