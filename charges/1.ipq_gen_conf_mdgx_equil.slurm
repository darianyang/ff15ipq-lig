#!/bin/bash
#SBATCH --job-name=mdgx_conf_gen_solv_equil_20_conf
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
PDB=mon
ITERATION=v00
LIB=${PDB}.lib
FRCMOD=${PDB}.frcmod

export DO_PARALLEL="mpirun -np 8 pmemd.MPI"
######################################################################

function pdb_vacuo_gen {
cd $ITERATION
# tleap input for capped dipeptide vacuo files
cat << EOF > tleap_vacuo.in
#source leaprc.protein.ff15ipq
source leaprc.gaff
loadoff $LIB
loadAmberParams $FRCMOD
${PDB} = loadpdb ${PDB}.pdb
check ${PDB}
set ${PDB} box {32.006 32.006 32.006}
saveAmberParm ${PDB} ${PDB}_V.top ${PDB}_V.crd
savepdb ${PDB} ${PDB}_V.pdb
quit
EOF

tleap -f tleap_vacuo.in > tleap_vacuo.out
echo "in vacuo top/crd/pdb files generated for ${PDB} dipeptide."
cd ../
}

function in_vacuo_min {
cd $ITERATION

# unrestrained in vacuo 10000 step minimization (500 SD)
pmemd -O -i ../amber/2_min.in -o 2_min.out \
-p ${PDB}_V.top -c ${PDB}_V.crd -r ${PDB}_V.rst &&

echo "in vacuo min finished."
cd ../ 
}

### Alternatively: copy over pdb, top, crd, min_rst files from v00 ###

function gen_confs_mdgx {
cd $ITERATION
# generate mdgx input file for generation of 20 conformations
####################################################
### the &configs options need specification here ###
####################################################
cat<<EOF > gen_confs.mdgx
&files
  -p ../${PDB}_V.top
  -c ../${PDB}_V.rst
  -o GenConformers.out
&end

&configs
  GridSample @5 @7 @9  @25  { -180.0 180.0 }   Krst 32.0 fbhw 30.0
  GridSample @7 @9 @25 @27  { -180.0 180.0 }   Krst 32.0 fbhw 30.0
  combine 1 2
  count 20
  verbose 1

  write   'pdb', 'inpcrd'
  outbase 'Conf', 'Conf'
  outsuff 'pdb', 'crd'
&end 
EOF

# option to remove GenConformers dir if previous run failed
rm -riv GenConformers

# store mdgx conformations in GenConformers directory
mkdir GenConformers
cd GenConformers
mdgx -i ../gen_confs.mdgx

echo "20 ${PDB} conformers generated in mdgx"
cd ../../
}

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
    #CMD="     source leaprc.protein.ff15ipq \n"
    CMD="     source leaprc.gaff \n"
    CMD="$CMD loadoff $LIB \n"
    CMD="$CMD loadamberparams $FRCMOD \n" 
    CMD="$CMD source leaprc.water.spceb \n"
    CMD="$CMD ${PDB} = loadPdb Conf${CONF}.pdb \n"
    CMD="$CMD solvateoct ${PDB} SPCBOX 12.0 \n"
    CMD="$CMD saveAmberParm ${PDB} Conf${CONF}.top Conf${CONF}.crd \n"
    CMD="$CMD quit"
    echo -e ${COMMAND} > tleap_solv.in
    tleap -f tleap_solv.in > tleap_solv.out &&

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

####################################################################
### The following functions are for mdgx conformation generation ###
#### If you choose to use mdgx, adjust the &configs parameters  ####
##### Another method is to use high temperature MD: (script 1) #####
####################################################################

pdb_vacuo_gen

in_vacuo_min

gen_confs_mdgx

solv_equil_confs

