#!/bin/bash
# RUN AS: $ bash 5.run_spe_gen2.sh
# submit new or resubmit failed or incomplete runs for SPE calculations
# the only thing different here is that we are using gen 2 files

###########################################################
####################### VARIABLES #########################
###########################################################
# CPUs per node to use for the slurm script
# note that this number should evenly divide into the number
# of CONFS per slurm job for max efficiency
CPUS=5
# arbitrary name of the iteration directory
ITERATION=v01
# 3 letter restype identifier for your molecule
PDB=mon
###########################################################
# NOTE: go to the end of file and change the conf ranges  #
#       to match the amount of conformations generated    #
###########################################################
###########################################################

# go to and set up ITERATION directory
cd $ITERATION &&
if [ ! -d logs ]; then
    mkdir logs
fi
if [ ! -d G2_CONFS_OOUT ]; then
    mkdir G2_CONFS_OOUT
fi

# function to submit a range of conformations
# arg $1 = conf range start
# arg $2 = cond range end  
function submit_spe_of_confs {
# run orca single-point energy calcs in vacuo for each conformation
cat << EOF > ${PDB}_RUN_ORCA_${1}-${2}_G2.slurm
#!/bin/bash
#SBATCH --job-name=${PDB}_${ITERATION}_SPE_CALC_G2_${1}_${2}
#SBATCH --cluster=invest
#SBATCH --partition=lchong
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=$CPUS
#SBATCH --mem=16g
#SBATCH --time=23:59:59  
#SBATCH --mail-user=dty7@pitt.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=logs/slurm_spe_${1}_${2}_G2.out
#SBATCH --error=logs/slurm_spe_${1}_${2}_G2.err

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
echo "\$(date)" >> logs/skip_${1}-${2}_G2.log
for I in {${1}..${2}} ; do

    # skip confs where SPE calculations are completed
    CONF_OOUT=\$(tail -1 G2_CONFS_OOUT/Conf\${I}.oout)
    if [[ "\$CONF_OOUT" == "TOTAL RUN TIME:"* ]] ; then
        echo "FOR PDB = $PDB : ITERATION = $ITERATION : CONF = \$I : RUN COMPLETED: SKIPPING" >> logs/skip_${1}-${2}_G2.log
        let "SKIP+=1"
        continue
    fi

    # skip if the initial conformation generation failed
    if [ ! -f G2_CONFS/Conf\${I}.pdb ] ; then
        echo "FOR PDB = $PDB : ITERATION = $ITERATION : CONF = \$I : INITIAL CONF NOT GENERATED: SKIPPING" >> logs/skip_${1}-${2}_G2.log
        continue
    fi

    # run orca spe calc
    echo -e "\tFOR PDB = $PDB : ITERATION = $ITERATION : CONF = \$I : RUN NOT COMPLETE: RERUNNING" >> logs/skip_${1}-${2}.log
    orca G2_CONFS/Conf\${I}.orca > G2_CONFS_OOUT/Conf\${I}.oout &
    let "NJOB+=1"

    # run on multiple CPUs
    if [ \${NJOB} -eq ${CPUS} ] ; then
        NJOB=0
        wait
    fi

done

echo -e "\nTOTAL SKIPPED CONFORMATIONS = \${SKIP}\n" >> logs/skip_${1}-${2}_G2.log
echo -e "------------------------------------------\n" >> logs/skip_${1}-${2}_G2.log

# finish any unevenly ran jobs
wait

# gives stats of job, wall time, etc.
crc-job-stats.py 
EOF
 
sbatch ${PDB}_RUN_ORCA_${1}-${2}_G2.slurm
echo -e "FINISHED $1 to $2 SPE CALC SUBMISSION FOR $PDB ITERATION:$ITERATION \n"
}

###########################################################
############# ADJUST THE FOLLOWING IF NEEDED ##############
###########################################################
# there probably won't be too many confs so just 1 run can work
submit_spe_of_confs 1 1000

