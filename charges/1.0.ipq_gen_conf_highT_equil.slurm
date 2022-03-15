#!/bin/bash
#SBATCH --job-name=high_T_conf_gen_then_equil
#SBATCH --cluster=invest
#SBATCH --partition=lchong
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem=16g
#SBATCH --time=11:59:59  
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
PDB=mon
ITERATION=gaff_02
LIB=${PDB}.lib
FRCMOD=${PDB}.frcmod

export DO_PARALLEL="mpirun -np 8 pmemd.MPI"
######################################################################

function high_T_conf_gen {
    # run for a single iteration
    cd $ITERATION

    # make a solvated structure using tleap
    #CMD="source leaprc.protein.ff15ipq \n"
    CMD="     source leaprc.gaff \n"
    CMD="$CMD loadoff $LIB \n"
    CMD="$CMD loadamberparams $FRCMOD \n" 
    CMD="$CMD source leaprc.water.spceb \n"
    #CMD="$CMD ${PDB} = loadPdb ${PDB}.pdb \n"
    CMD="$CMD ${PDB} = loadmol2 ${PDB}.mol2 \n"
    CMD="$CMD solvateoct ${PDB} SPCBOX 12.0 \n"
    CMD="$CMD saveAmberParm ${PDB} ${PDB}.top ${PDB}.crd \n"
    CMD="$CMD quit"
    echo -e $CMD > tleap_solv.in
    tleap -f tleap_solv.in > tleap_solv.out &&

    # run amber scripts for high temperature conformation generation

    # unrestrained 10000 step minimization (500 SD)
    $DO_PARALLEL -O -i ../amber/2_min.in -o 2_min.out \
        -p ${PDB}.top -c ${PDB}.crd -r 2_min.rst &&
    echo $PDB unrestrained min finished

    # 20 ps unrestrained NVT temp equilibration : Langevin thermostat (450K)
    $DO_PARALLEL -O -i ../amber/3_eq1.in -o 3_eq1.out \
        -p ${PDB}.top -c 2_min.rst -r 3_eq1.rst &&
    echo $PDB unrestrained 450K eq1 finished

    # 1 ns unrestrained NPT volume equilibration : Langevin thermostat (450K) and MC barostat
    $DO_PARALLEL -O -i ../amber/4_eq2.in -o 4_eq2.out \
        -p ${PDB}.top -c 3_eq1.rst -r 4_eq2.rst &&
    echo $PDB unrestrained 450K eq2 finished

    # 10 ns unrestrained NPT production run : Langevin thermostat (450K) and MC barostat
    # rst files are saved every 500 ps, totaling to 20 conformations generated
    $DO_PARALLEL -O -i ../amber/5_genconf.in -o 5_genconf.out \
        -p ${PDB}.top -c 4_eq2.rst -r 5_genconf.rst &&
    echo $PDB unrestrained 450K conf gen finished

    # make a conformers directory and move rst files
    mkdir GenConformers

    # clean up high_T conformers output
    CONF=1
    for RST in {250000..5000000..250000} ; do
        # move conf rst files to GenConformers and rename
        mv 5_genconf.rst_$RST GenConformers/Conf${CONF}.rst && 
        
        # TODO: strip with cpptraj to be consistent with mdgx conf gen?
        # make pdb file, centered with no CRYST1 record of box coordinates
        ambpdb -p ${PDB}.top -c GenConformers/Conf${CONF}.rst -ctr -nobox > GenConformers/Conf${CONF}.pdb  
        let "CONF++"
    done

    cd ..
}

function equil_confs {
    cd $ITERATION/GenConformers
    # for each conformation,
    for CONF in {1..20}; do
        # make and go into subdirectory
        mkdir Conf${CONF}
        if [[ -f Conf${CONF}.rst || -f Conf${CONF}.pdb ]] ; then
            mv Conf${CONF}.rst Conf${CONF}
            mv Conf${CONF}.pdb Conf${CONF}
        fi
        cd Conf${CONF}
    
        # restrained 2000 step minimization (500 SD)
        $DO_PARALLEL -O -i ../../../amber/6.1_min.in -o 6.1_min.out \
            -p ../../${PDB}.top -c Conf${CONF}.rst -r 6.1_min.rst -ref Conf${CONF}.rst &&
        echo ${CONF}.min finished
    
        # 20 ps restrained NVT equilibration using Langevin thermostat
        $DO_PARALLEL -O -i ../../../amber/6.2_eq1.in -o 6.2_eq1.out \
            -p ../../${PDB}.top -c 6.1_min.rst -r 6.2_eq1.rst -ref 6.1_min.rst &&
        echo ${CONF}.eq1 finished
    
        # 100 ps restrained NPT equilibration using Langevin thermostat and MC barostat
        $DO_PARALLEL -O -i ../../../amber/6.3_eq2.in -o 6.3_eq2.out \
            -p ../../${PDB}.top -c 6.2_eq1.rst -r 6.3_eq2.rst -ref 6.2_eq1.rst &&
        echo ${CONF}.eq2 finished
    
        cd ../
    done
    
    echo "Done solvating and equilibrating ${PDB} conformations."
    cd ../../
}

#########################################################################
### The following functions are for high temp conformation generation ###
#########################################################################
high_T_conf_gen &&
equil_confs

