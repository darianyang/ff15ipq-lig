#!/bin/bash
# check that all conformations finished grid file generation successfully
# takes 1 optional arg 1 - can be "resub" to resubmit failed runs

ITERATION=gaff_02
PDB=mon

FAIL=0
cd $ITERATION/GenConformers
for CONF in {1..20} ; do
    cd Conf$CONF

    # check for grid output and save as bool
    if [[ -f grid_output.vacu && -f grid_output.solv ]] ; then
        GRID=true
    else
        GRID=false
    fi

    VACU_OUT=$(tail -1 qm_output.vacu)
    SOLV_OUT=$(tail -1 qm_output.solv)
    if [[ "$VACU_OUT" == "TOTAL RUN TIME:"* && "$SOLV_OUT" == "TOTAL RUN TIME:"* ]] ; then
        echo "RES = ${PDB^^} : CONF = $CONF - RUN COMPLETED SUCCESSFULLY | GRID = ${GRID^^}"
    else
        echo "WARNING: RES = ${PDB^^} : CONF = $CONF - RUN NOT COMPLETED SUCCESSFULLY | GRID = ${GRID^^}"
        let "FAIL++"

        # resubmit if arg 1 = resub
        if [ $1 = "resub" ] ; then
            echo -e "\tRESUBMITTING: RES = ${PDB^^} : CONF = $CONF"
            if [ "$GRID" = true ] ; then
                echo "Removing grid output files to resubmit... are sure this is what you want?"
                rm -vi grid_output.*
            fi
            # resubmit slurm script for this conf
            sbatch conf_${CONF}_mdgx_grid_gen.slurm
        fi

    fi
    cd ..
done
echo "TOTAL FAILED CONFS = $FAIL"

if [[ $FAIL -ge 1 && $1 != "resub" ]] ; then
    echo -e "\n\tTo resubmit the failed runs, run this script with arg \$1 = resub\n"
fi
