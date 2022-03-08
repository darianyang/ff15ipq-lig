#!/bin/bash
#SBATCH --job-name=high_T_conf_gen_then_equil
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=16g
#SBATCH --time=3:59:59  
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
LIB=19F_FF15IPQ_V02.lib
FRCMOD=19F_FF15IPQ_V00.frcmod

export DO_PARALLEL="mpirun -np 8 pmemd.MPI"
######################################################################

function high_T_conf_gen {
    # run for a single iteration
    cd $ITERATION

    # make a solvated structure using tleap

    # write tleap file for solvation of vacuo structures
    CMD="source leaprc.protein.ff15ipq \n"
    CMD="$CMD loadoff $LIB \n"
    CMD="$CMD loadamberparams $FRCMOD \n" 
    CMD="$CMD source leaprc.water.spceb \n"
    CMD="$CMD ${PDB} = loadPdb Conf${CONF}.pdb \n"
    CMD="$CMD solvateoct ${PDB} SPCBOX 12.0 \n"
    CMD="$CMD saveAmberParm ${PDB} Conf${CONF}.top Conf${CONF}.crd \n"
    CMD="$CMD quit"
    echo -e $CMD > tleap_solv.in
    tleap -f tleap_solv.in > tleap_solv.out

    # run amber scripts for high temperature conformation generation

    # unrestrained 10000 step minimization (500 SD)
    $DO_PARALLEL -O -i amber/2_min.in -o 2_min.out \
        -p Conf${CONF}.top -c Conf${CONF}.crd -r 6.1_min.rst -ref Conf${CONF}.crd &&
    echo $PDB unrestrained min finished

    # 20 ps unrestrained NVT temp equilibration : Langevin thermostat (450K)
    $DO_PARALLEL -O -i amber/6.2_eq1.in -o 6.2_eq1.out \
        -p Conf${CONF}.top -c 6.1_min.rst -r 6.2_eq1.rst -ref 6.1_min.rst &&
    echo $PDB unrestrained eq1 finished

    # 100 ps unrestrained NPT volume equilibration : Langevin thermostat (450K) and MC barostat
    $DO_PARALLEL -O -i amber/6.3_eq2.in -o 6.3_eq2.out \
        -p Conf${CONF}.top -c 6.2_eq1.rst -r 6.3_eq2.rst -ref 6.2_eq1.rst &&
    echo $PDB unrestrained eq2 finished

    # 10 ns unrestrained NPT production run : Langevin thermostat (450K) and MC barostat
    $DO_PARALLEL -O -i amber/6.3_eq2.in -o 6.3_eq2.out \
        -p Conf${CONF}.top -c 6.2_eq1.rst -r 6.3_eq2.rst -ref 6.2_eq1.rst &&
    echo $PDB unrestrained 450K conf gen finished

    # make a conformers directory and move rst files
    mkdir -p $ITERATION/GenConformers
    # TODO: what are the rst files called?

    # finished with this iteration
    cd ..
}

# TODO: update to equil rst high T output files
function equil_confs {
    cd $ITERATION/GenConformers
    # for each conformation,
    for CONF in {1..20}; do
        # make and go into subdirectory
        mkdir Conf${CONF}
        mv Conf${CONF}.pdb Conf${CONF}
        mv Conf${CONF}.crd Conf${CONF}
        cd Conf${CONF}
    
        # restrained 2000 step minimization (500 SD)
        $DO_PARALLEL -O -i amber/6.1_min.in -o 6.1_min.out \
            -p Conf${CONF}.top -c Conf${CONF}.crd -r 6.1_min.rst -ref Conf${CONF}.crd &&
        echo ${CONF}.min finished
    
        # 20 ps restrained NVT equilibration using Langevin thermostat
        $DO_PARALLEL -O -i amber/6.2_eq1.in -o 6.2_eq1.out \
            -p Conf${CONF}.top -c 6.1_min.rst -r 6.2_eq1.rst -ref 6.1_min.rst &&
        echo ${CONF}.eq1 finished
    
        # 100 ps restrained NPT equilibration using Langevin thermostat and MC barostat
        $DO_PARALLEL -O -i amber/6.3_eq2.in -o 6.3_eq2.out \
            -p Conf${CONF}.top -c 6.2_eq1.rst -r 6.3_eq2.rst -ref 6.2_eq1.rst &&
        echo ${CONF}.eq2 finished
    
        cd ../
    done
    
    echo "Done solvating and equilibrating ${PDB} conformations."
    cd ../../
}

#########################################################################
### The following functions are for high temp conformation generation ###
#########################################################################
high_T_conf_gen
equil_confs

