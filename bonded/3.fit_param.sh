#!/bin/bash
# 3.fit_param.sh
# Execute ipq parameter fitting protocols

PDB=mon
ITERATION=v02
FRCMOD=mon.frcmod

cd $ITERATION &&

# make parameter fitting script for all RES_CLASSES
cat << EOF > FIT_${ITERATION}.in
&files
  -parm /ihome/crc/build/amber/amber18_x64/amber18/dat/leap/parm/gaff.dat
  -fmod $FRCMOD
  -d FIT_${ITERATION}.frcmod
  -o FIT_${ITERATION}.out
&end

&param
  System    ${PDB}_V.top     concat_coords.cdf    energies.dat
  ParmOutput    frcmod
  verbose       1,
  eunits        hartree,
  accrep        report.m

  % eliminate conformations far outside of the norm for the system
  % default 0 (do not remove outliers)
  elimsig       1,
  % tolerance for deviation from mean energy value in sigmas (default 5)
  ctol          5,
  %esigtol       5

  % 0 for file akin to frcmod file, default 1 (write all parameters)
  %repall        1,

  % Angle fitting input
  fita          ce  c2  n
  FitAnglEq     1,
  arst          0.002,
  arstcpl       1,  

  % Torsion fitting input
  fith          n   c3  ce  c
  fith          ca  c3  ce  c
  fith          h1  c3  ce  c
  fith          n   c3  ce  c2
  fith          ca  c3  ce  c2
  fith          h1  c3  ce  c2
  %hrst          0.0002,
  hrst          0.002,
&end
EOF

mdgx -i FIT_${ITERATION}.in -O

