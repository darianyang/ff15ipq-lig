#!/bin/bash
# 2.fit_param.sh
# Execute ipq parameter fitting protocols

ITER=v01
FRCMOD=mon.frcmod

cd $ITER &&

# make parameter fitting script for all RES_CLASSES
cat << EOF > FIT_${ITER}.in
&files
  %-parm /ihome/crc/build/amber/amber18_x64/amber18/dat/leap/parm/parm15ipq_10.3.dat
  -parm /ihome/crc/build/amber/amber18_x64/amber18/dat/leap/parm/gaff.dat
  -fmod ../$FRCMOD
  -d FIT_${ITER}.frcmod
  -o FIT_${ITER}.out
&end

&param
  System    ${RES}/${RES}_V.top     ${RES}/concat_coords.cdf    ${RES}/energies.dat
  ParmOutput    frcmod
  verbose       1,
  eunits        hartree,
  accrep        report.m

  % eliminate conformations far outside of the norm for the system
  % default 0 (do not remove outliers)
  elimsig       1,
  % tolerance for deviation from mean energy value in sigmas (default 5)
  ctol          5,

  % 0 for file akin to frcmod file, default 1 (write all parameters)
  %repall        0,
  
  % Torsion fitting input
  fith          n   c3  ce  c
  fith          ca  c3  ce  c
  fith          h1  c3  ce  c
  fith          n   c3  ce  c2
  fith          ca  c3  ce  c2
  fith          h1  c3  ce  c2
  hrst          0.0002,
&end
EOF

mdgx -i FIT_${ITER}.in -O
