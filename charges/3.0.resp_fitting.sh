#!/bin/bash
# set up REsP charge fitting file for 19F after grid files generation

ITER=gaff_00
PDB=mon
LIB=${PDB}.lib
# name of the input file to be generated
RESP=$ITER/resp.in


# make a vacuum phase topology file (PDB_V.top) if using high_T conf gen
if [ ! -f $ITER/${PDB}_V.top ] ; then
    CMD=" strip :WAT \n"
    CMD="$CMD parmout $ITER/${PDB}_V.top \n"
    CMD="$CMD go"
    echo -e "$CMD" > $ITER/parmed.in
    parmed -p $ITER/${PDB}.top -i $ITER/parmed.in > $ITER/parmed.out
fi
 

# begin head of resp input file
echo "
&files
  -o    $ITER/resp.out
&end

&fitq" > $RESP

# input vacuum and solvent reacion field potential quantum calculations from IPolQ
# COLUMNS: ipolq_command | vacu_grid_file | solv_grid_file | topology | conf_weight 
for CONF in {1..20} ; do
    GRID_PATH=$ITER/GenConformers/Conf$CONF
    echo "  ipolq  $GRID_PATH/grid_output.vacu  $GRID_PATH/grid_output.solv   $ITER/${PDB}_V.top   1.0" >> $RESP
done

echo "
  % Fit parameters for the REsP 
  pnrg      0.0
  flim      0.39
  nfpt      3750

  % Calculation settings
  maxmem    6GB
  verbose   1

  % Constraints on blocking group equivalent atoms
  equalq    ':ACE & @H1,H2,H3'
  equalq    ':ACE & @CH3'
  equalq    ':ACE & @C'
  equalq    ':ACE & @O'
  equalq    ':NME & @HH31,HH32,HH33'
  equalq    ':NME & @CH3'
  equalq    ':NME & @N'
  equalq    ':NME & @H'

  % Constraints on amino acid equivalent atoms
  equalq    ':W4F,W5F,W5F,W7F & @HB2,HB3'
  equalq    ':Y3F,YDF & @HB2,HB3'
  equalq    ':YDF & @HD1,HD2'
  equalq    ':YDF & @F3Y,F5Y'
  equalq    ':YDF & @CD1,CD2'
  equalq    ':YDF & @CE1,CE2'
  equalq    ':F4F,FTF & @HB2,HB3'
  equalq    ':F4F,FTF & @HD1,HD2'
  equalq    ':F4F,FTF & @HE1,HE2'
  equalq    ':F4F,FTF & @CD1,CD2'
  equalq    ':F4F,FTF & @CE1,CE2'
  equalq    ':FTF & @F1C,F2C,F3C'

  % Restrain charges on buried atoms
  minq      ':NME & @CH3'
  minq      ':ACE & @CH3'
  minq      '@CB'

  % Force constant by which to restrain charges
  minqwt    1.0e-2

&end" >> $RESP

#mdgx -i $RESP &&

# check the output resp file for self-consistent charge convergence
# args: 1 = library file, 2 = resp output file
#python 3.check_converge.py $ITER/$LIB $ITER/resp.out

