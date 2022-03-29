#!/bin/bash
# RUN AS: $ bash 1.run_spe.sh
# submit new or resubmit failed or incomplete runs for SPE calculations
#   I can't get this to work on multiple nodes, but I instead will run
#   multiple jobs to split up the conformations
#       e.g. run 1-500 and 501-1000 on two slurm submissions

###########################################################
####################### VARIABLES #########################
###########################################################
# CPUs per node to use for the slurm script
# note that this number should evenly divide into the number
# of CONFS per slurm job for max efficiency
CPUS=20
# arbitrary name of the iteration directory
ITERATION=v00
# 3 letter restype identifier for your molecule
PDB=mon
###########################################################
# NOTE: go to the end of file and change the conf ranges  #
#       to match the amount of conformations generated    #
###########################################################
###########################################################

cd $ITERATION &&

# function to submit a range of conformations
# arg $1 = conf range start
# arg $2 = cond range end  
function submit_spe_of_confs {
# run orca single-point energy calcs in vacuo for each conformation
cat << EOF > ${PDB}_RUN_ORCA_${1}-${2}.slurm
#!/bin/bash
#SBATCH --job-name=${PDB}_${ITERATION}_SPE_CALC_${1}_${2}
#SBATCH --cluster=smp
#SBATCH --partition=smp
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=$CPUS
#SBATCH --mem=16g
#SBATCH --time=23:59:59  
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
SKIP=0
echo "\$(date)" >> skip_${1}-${2}.log
for I in {${1}..${2}} ; do

    # skip confs where SPE calculations are completed
    CONF_OOUT=\$(tail -1 CONFS_OOUT/Conf\${I}.oout)
    if [[ "\$CONF_OOUT" == "TOTAL RUN TIME:"* ]] ; then
        echo "FOR PDB = $PDB : ITERATION = $ITERATION : CONF = \$I : RUN COMPLETED: SKIPPING" >> skip_${1}-${2}.log
        let "SKIP+=1"
        continue
    fi

    orca CONFS/Conf\${I}.orca > CONFS_OOUT/Conf\${I}.oout &
    let "NJOB+=1"

    if [ \${NJOB} -eq ${CPUS} ] ; then
        NJOB=0
        wait
    fi

done

echo -e "\nTOTAL SKIPPED CONFORMATIONS = \${SKIP}" >> skip_${1}-${2}.log

# finish any unevenly ran jobs
wait

# run EXTRACT ENERGIES script
mdgx -i ${PDB}_concat.mdgx -O

# gives stats of job, wall time, etc.
crc-job-stats.py 
EOF
 
# extract the energies from each conformation SPE QM calc
cat << EOF > ${PDB}_concat.mdgx
&files
  -p      ${PDB}_V.top
  -o      concat.out
  -d      energies.dat
  -x      concat_coords.cdf
&end

&speval
  data    CONFS_OOUT/Conf*.oout
&end
EOF

sbatch ${PDB}_RUN_ORCA_${1}-${2}.slurm
echo -e "FINISHED $1 to $2 SPE CALC SUBMISSION FOR $PDB ITERATION:$ITERATION \n"
}

###########################################################
############# ADJUST THE FOLLOWING IF NEEDED ##############
###########################################################
# Here, I am splitting my total confs (1000) into 10 jobs #
###########################################################
#for CONF in {100..1000..100} ; do
#    submit_spe_of_confs $((CONF - 99)) $CONF
#done

# or run this line if you want to run all on one job/node
# I like to run this as a way of checking if everything ran
# and it will also run the failed jobs
submit_spe_of_confs 1 1000

