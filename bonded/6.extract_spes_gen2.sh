#!/bin/bash
# RUN AS: $ bash 6.extract_spes_gen2.dat

PDB=mon
ITERATION=v01

cd $ITERATION

# in mdgx: extract the energies from each conformation SPE QM calc
cat << EOF > ${PDB}_concat_G2.mdgx
&files
  -p      ${PDB}_V_G2.top
  -o      concat_G2.out
  -d      energies_G2.dat
  -x      concat_coords_G2.cdf
&end

&speval
  data    G2_CONFS_OOUT/Conf*.oout
&end
EOF

# run EXTRACT ENERGIES script
mdgx -i ${PDB}_concat_G2.mdgx -O
