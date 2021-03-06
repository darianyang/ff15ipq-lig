#!/bin/bash
# RUN AS: $ bash 2.extract_spes.dat

PDB=mon
ITERATION=v02

cd $ITERATION

# in mdgx: extract the energies from each conformation SPE QM calc
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

# run EXTRACT ENERGIES script
mdgx -i ${PDB}_concat.mdgx -O
