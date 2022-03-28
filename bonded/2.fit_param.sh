#!/bin/bash
# 2.fit_param.sh
# Execute ipq parameter fitting protocols

ITER=V01
FRCMOD=19F_FF15IPQ_FIT_V00_GEN2.frcmod

cd $ITER &&

# make parameter fitting script for all RES_CLASSES
echo "
&files
  %-parm /ihome/crc/build/amber/amber18_x64/amber18/dat/leap/parm/parm15ipq_10.3.dat
  -parm /ihome/crc/build/amber/amber18_x64/amber18/dat/leap/parm/gaff.dat
  -fmod ../$FRCMOD
  -d 19F_FF15IPQ_FIT_${ITER}.frcmod
  -o FIT_${ITER}.out
&end

&param
" > FIT_${ITER}.in

echo "  System    ${RES}/${RES}_V.top     ${RES}/concat_coords.cdf    ${RES}/energies.dat" >> FIT_${ITER}.in

echo "
  ParmOutput    frcmod
  eunits        hartree,
  accrep        report.m
  elimsig       1,
  esigtol       4,
  verbose       1,
  %repall        2,
  
  % Torsion fitting input
  fith          F  3C CA CA
  %fith          F  CA CA CA
  %fith          F  CA CB CA
  %fith          F  CA CN CA
  %fith          3C CA CA CA
  hrst          0.0002,
&end
" >> FIT_${ITER}.in

mdgx -i FIT_${ITER}.in -O
