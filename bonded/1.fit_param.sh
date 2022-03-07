#!/bin/bash
# 1.fit_param.sh
# Execute ipq parameter fitting protocols

# load env
source ~/.setup.sh

ITER=V01
LIB_VAC=19F_FF15IPQ_V03_VAC.lib
FRCMOD=19F_FF15IPQ_FIT_V00_GEN2.frcmod

RES_CLASSES=(W4F W5F W6F W7F Y3F YDF F4F FTF)

cd $ITER &&

# make parameter fitting script for all RES_CLASSES
echo "
&files
  -parm /ihome/crc/build/amber/amber18_x64/amber18/dat/leap/parm/parm15ipq_10.3.dat
  -fmod ../$FRCMOD
  -d 19F_FF15IPQ_FIT_${ITER}.frcmod
  -o FIT_${ITER}.out
&end

&param
" > FIT_${ITER}.in

for RES in ${RES_CLASSES[@]} ; do
  echo "  System    ${RES}/${RES}_V.top     ${RES}/concat_coords.cdf    ${RES}/energies.dat" >> FIT_${ITER}.in
done

echo "
  ParmOutput    frcmod
  eunits        hartree,
  accrep        report.m
  elimsig       1,
  esigtol       4,
  verbose       1,
  %repall        2,
  
  % Bonded fitting input
  fitb          3C CA
  fitb          3C F
  FitBondEq     1,
  brst          0.0002,

  % Angle fitting input
  fita          CB CA F
  fita          CN CA F
  fita          C  CA F
  fita          3C CA CA
  fita          CA 3C F
  fita          F  3C F
  FitAnglEq     1,
  arst          0.0002,
  %arst          0.00005,
  %arstcpl       114.59,
  arstcpl       1.0,

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
