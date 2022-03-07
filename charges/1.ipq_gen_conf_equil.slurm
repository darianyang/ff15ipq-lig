#!/bin/bash
#SBATCH --job-name=solv_min_equil_20_conf_F4F
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=16g
#SBATCH --time=1:59:59  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=job_logs/slurm_equil.out
#SBATCH --error=job_logs/slurm_equil.err

# *** make sure that job_logs directory is setup ***

# load appropriate modules, first purge all modules 
# then load in intel (a prereq for loading in amber) and then amber 
module purge
module load intel/2017.3.196
module load amber/18

# echo commands to stdout
set -x 

######################################################################
# set variables
PDB=F4F
ITERATION=v03
LIB=$HOME/bgfs-dty7/19F_ff15ipq/19F_FF15IPQ_V02.lib
FRCMOD=$HOME/bgfs-dty7/19F_ff15ipq/19F_FF15IPQ_V00.frcmod

export DO_PARALLEL="mpirun -np 8 pmemd.MPI"
######################################################################

function solv_equil_confs {
cd $ITERATION/GenConformers
# for each conformation,
for CONF in {1..20}; do
    # make and go into subdirectory
    mkdir Conf${CONF}
    mv Conf${CONF}.pdb Conf${CONF}
    mv Conf${CONF}.crd Conf${CONF}
    cd Conf${CONF}

    # write tleap file for solvation of vacuo structures
    COMMAND="source leaprc.protein.ff15ipq \n"
    COMMAND="${COMMAND}loadoff $LIB \n"
    COMMAND="${COMMAND}loadamberparams $FRCMOD \n" 
    COMMAND="${COMMAND}source leaprc.water.spceb \n"
    COMMAND="${COMMAND}${PDB} = loadPdb Conf${CONF}.pdb \n"
    COMMAND="${COMMAND}solvateoct ${PDB} SPCBOX 12.0 \n"
    COMMAND="${COMMAND}saveAmberParm ${PDB} Conf${CONF}.top Conf${CONF}.crd \n"
    COMMAND="${COMMAND}quit"
    echo -e ${COMMAND} > tleap_solv.in
    tleap -f tleap_solv.in > tleap_solv.out

    # restrained 2000 step minimization (500 SD)
    $DO_PARALLEL -O -i ../../../../amber/6.1_min.in -o 6.1_min.out \
        -p Conf${CONF}.top -c Conf${CONF}.crd -r 6.1_min.rst -ref Conf${CONF}.crd &&
    echo ${CONF}.min finished

    # 20 ps restrained NVT equilibration using Langevin thermostat
    $DO_PARALLEL -O -i ../../../../amber/6.2_eq1.in -o 6.2_eq1.out \
        -p Conf${CONF}.top -c 6.1_min.rst -r 6.2_eq1.rst -ref 6.1_min.rst &&
    echo ${CONF}.eq1 finished

    # 100 ps restrained NPT equilibration using Langevin thermostat and MC barostat
    $DO_PARALLEL -O -i ../../../../amber/6.3_eq2.in -o 6.3_eq2.out \
        -p Conf${CONF}.top -c 6.2_eq1.rst -r 6.3_eq2.rst -ref 6.2_eq1.rst &&
    echo ${CONF}.eq2 finished

    cd ../
done

echo "Done solvating and equilibrating ${PDB} conformations."
cd ../../
}

solv_equil_confs

