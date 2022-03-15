#!/bin/bash
# set up REsP charge fitting file for 19F after grid files generation

ITERATION=gaff_02
PDB=mon
LIB=${PDB}.lib
# name of the input file to be generated
RESP=$ITERATION/resp.in


# make a vacuum phase topology file (PDB_V.top) if using high_T conf gen
if [ ! -f $ITERATION/${PDB}_V.top ] ; then
    CMD=" strip :WAT \n"
    CMD="$CMD parmout $ITERATION/${PDB}_V.top \n"
    CMD="$CMD go"
    echo -e "$CMD" > $ITERATION/parmed.in
    parmed -p $ITERATION/${PDB}.top -i $ITERATION/parmed.in > $ITERATION/parmed.out
fi
 
# clean up previous run topology file
if [[ -f $ITERATION/${PDB}_V.top. && -f $ITERATION/resp.out ]] ; then
    echo -e "\nCleaning up previous run files:"
    rm -v $ITERATION/{${PDB}_V.top.,resp.out}
    echo ""
fi

# begin head of resp input file
echo "
&files
  -o    $ITERATION/resp.out
&end

&fitq" > $RESP

# input vacuum and solvent reacion field potential quantum calculations from IPolQ
# COLUMNS: ipolq_command | vacu_grid_file | solv_grid_file | topology | conf_weight 
for CONF in {1..20} ; do
    GRID_PATH=$ITERATION/GenConformers/Conf$CONF
    echo "  ipolq  $GRID_PATH/grid_output.vacu  $GRID_PATH/grid_output.solv   $ITERATION/${PDB}_V.top   1.0" >> $RESP
done

echo "
  % The minimum proximity of any two points to be included in the fit
  flim      0.39

  % The number of fitting points to select from each electrostatic potential grid 
  nfpt      3750

  % Calculation settings
  maxmem    6GB
  verbose   1

  % Constraints on equivalent atoms
  equalq    ':MON & @H,H1,H2'
  equalq    ':MON & @H3,H4'
  equalq    ':MON & @H5,H6,H7'

  % Restrain charges on buried atoms
  minq      ':MON & @C7'
  minq      ':MON & @C8'
  minq      ':MON & @C3'

  % Force constant by which to restrain charges
  minqwt    1.0e-2

  % Sum of all charges (total charge restraint)
  qtot      0.0

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%% The following solvent probe parameters are for SPC/Eb %%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Lennard-Jones sigma (Å) of solvent probe
  psig      3.1657
  % Lennard-Jones epsilon (kcal/mol) of solvent probe
  peps      0.1553
  % The probe arm; points on the electrostatic potential grid that 
  % would be inaccessible to the solvent probe may still be included 
  % in the fit if they are within the probe arm’s reach
  parm      1.01

  % Maximum Lennard-Jones energy (kcal/mol) of solvent probe at which
  % a point will qualify for inclusion in the fit
  pnrg      0.0

&end" >> $RESP

mdgx -i $RESP &&

# check the output resp file for self-consistent charge convergence
# args: 1 = library file, 2 = resp output file
echo -e "\nRUNNING: python 3.check_converge.py $ITERATION/$LIB $ITERATION/resp.out"
python 3.1.check_converge.py $ITERATION/$LIB $ITERATION/resp.out

