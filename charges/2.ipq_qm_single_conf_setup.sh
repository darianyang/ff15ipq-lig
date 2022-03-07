#!/bin/bash
##############################################################
##### ipq charge derivation: QM and grid file generation #####
##############################################################
# ARG 1 = Conformation Int

CONF=$1

# contingent step to delete old files
if [ -f "ipolq.out" ]; then
    rm -v ipolq.out
fi
if [ -f "mdcrd" ]; then
    rm -v mdcrd
fi
# delete files from old run
if [ -f "restrt" ]; then
    rm -v restrt
    rm -v qm*
    rm -v *_output*
    rm -v *_input*
    rm -v *.tmp*
    rm -rv scratch
fi

# if needed: make dir to use during QM
if [ ! -d scratch ]; then
    mkdir -v scratch
fi

# write ipq qm mdgx input file
cat << EOF > ipq_qm_mp2_grid_gen.mdgx
&files
  -p Conf${CONF}.top
  -c 6.3_eq2.rst
  -o ipolq.out
&end

&cntrl
  imin      = 0
  irest     = 0
  dt        = 0.002
  nstlim    = 250000
  ntp       = 0
  ntt       = 3
  tempi     = 298.0
  temp0     = 298.0
  gamma_ln  = 1.0
  rigidbond = 1
  rigidwat  = 1
  es_cutoff     = 10.0
  vdw_cutoff    = 10.0
  ntpr      = 500
  ntwr      = 250000
  ntwx      = 500
  iwrap     = 1,
&end

&ipolq
  solute    = ':1-3'
  ntqs      = 1000
  nqframe   = 200
  nsteqlim  = 50000
  nblock    = 4
  verbose   = 1
  modq      = ':WAT & @H1'   0.5173
  modq      = ':WAT & @H2'   0.5173
  modq      = ':WAT & @O'   -1.0346
  nqshell   = 3
  nqphpt    = 100
  qshellx   = 2.0
  qshell1   = 5.0
  qshell2   = 5.5
  qshell3   = 6.0
  minqwt    = 0.01
  nvshell   = 3
  nvphpt    = 20
  vhsell1   = 0.3
  vshell2   = 0.5
  vshell3   = 0.7
  qmprog    = 'orca'
  prepqm    = "PATH=/ihome/crc/install/gcc-5.4.0/openmpi/1.6.5/bin:\$PATH"
  prepqm    = "LD_LIBRARY_PATH=/ihome/crc/install/gcc-5.4.0/openmpi/1.6.5/lib:\$LD_LIBRARY_PATH"
  qmpath    = '/ihome/crc/build/orca/3.0.3/orca'
  uvpath    = '/ihome/crc/build/orca/3.0.3/orca_vpot'
  maxcore   = 96000
  qmlev     = MP2
  basis     = cc-pvTZ
  unx       = 121
  uny       = 121
  unz       = 121
  uhx       = 0.2
  uhy       = 0.2
  uhz       = 0.2
  qmcomm    = qm_input
  qmresult  = qm_output
  rqminp    = 1
  rqmchk    = 1
  rqmout    = 1
  rcloud    = 1
  grid      = grid_output
  ptqfi     = srfp_output
&end
EOF


