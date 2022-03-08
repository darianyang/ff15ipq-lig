#!/bin/bash
# pipeline for ipq style charge derivation for fluorinated amino acids
# this script is best run locally or with a crc-interactive session

######################################################################
# set variables
PDB=F4F
ITERATION=v03
LIB=$HOME/bgfs-dty7/19F_ff15ipq/19F_FF15IPQ_V02.lib
FRCMOD=$HOME/bgfs-dty7/19F_ff15ipq/19F_FF15IPQ_V00.frcmod

######################################################################

function progress_check {
echo "Check files/output so far. Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
}

function file_setup {
mkdir -v $ITERATION
cp -v ${PDB}.pdb $ITERATION
cd $ITERATION

# edit pdb file: get rid of connecting lines, change HETATOM to ATOM
sed -i '/CONECT/d' ${PDB}.pdb
sed -i 's/HETATM/ATOM  /g' ${PDB}.pdb

echo "dir: $ITERATION prepped."
#progress_check
cd ../
}

function pdb_vacuo_gen {
cd $ITERATION
# tleap input for capped dipeptide vacuo files
cat << EOF > tleap_vacuo.in
source leaprc.protein.ff15ipq
loadoff $LIB
loadAmberParams $FRCMOD
${PDB} = sequence { ACE ${PDB} NME }
check ${PDB}
set ${PDB} box {32.006 32.006 32.006}
saveAmberParm ${PDB} ${PDB}_V.top ${PDB}_V.crd
savepdb ${PDB} ${PDB}_V.pdb
quit
EOF

tleap -f tleap_vacuo.in > tleap_vacuo.out
echo "in vacuo top/crd/pdb files generated for ${PDB} dipeptide."
#progress_check
cd ../
}


function in_vacuo_min {
cd $ITERATION

# unrestrained in vacuo 10000 step minimization (500 SD)
pmemd -O -i ../../amber/2_min.in -o 2_min.out \
-p ${PDB}_V.top -c ${PDB}_V.crd -r ${PDB}_V.rst &&

echo "in vacuo min finished."
#progress_check
cd ../ 
}

### Alternatively: copy over pdb, top, crd, min_rst files from v00 ###

function gen_confs_mdgx {
cd $ITERATION
# generate mdgx input file for generation of 20 conformations
cat<<EOF > gen_confs.mdgx
&files
  -p ../${PDB}_V.top
  -c ../${PDB}_V.rst
  -o GenConformers.out
&end

&configs
  GridSample @5 @7 @9  @25  { -180.0 180.0 }   Krst 32.0 fbhw 30.0
  GridSample @7 @9 @25 @27  { -180.0 180.0 }   Krst 32.0 fbhw 30.0
  combine 1 2
  count 20
  verbose 1

  write   'pdb', 'inpcrd'
  outbase 'Conf', 'Conf'
  outsuff 'pdb', 'crd'
&end 
EOF

# option to remove GenConformers dir if previous run failed
rm -riv GenConformers

# store mdgx conformations in GenConformers directory
mkdir GenConformers
cd GenConformers
mdgx -i ../gen_confs.mdgx

echo "20 ${PDB} conformers generated in mdgx"
#progress_check
cd ../../
}


####################################################################
### The following functions are for mdgx conformation generation ###
##### Another method is to use high temperature MD: (script 1) #####
####################################################################

file_setup

pdb_vacuo_gen

in_vacuo_min

gen_confs_mdgx



