#!/bin/bash
# pipeline for ipq style charge derivation for fluorinated amino acids
# this script is best run locally or with a crc-interactive session

######################################################################
# set variables
PDB=F4F
ITERATION=v00

# remember to adjust for frcmod incorporation options
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

function stage1_file_setup {
### stage 1: generate 20 conformations of target molecule
### directory and file setup

mkdir -v $ITERATION
cp -v ${PDB}.pdb $ITERATION
cd $ITERATION

# edit pdb file: get rid of connecting lines, change HETATOM to ATOM
sed -i '/CONECT/d' ${PDB}.pdb
sed -i 's/HETATM/ATOM  /g' ${PDB}.pdb

# save new pdb file of PDB_solo
# instead - start with solo and build dipeptide later in tleap
#cat ${PDB}.pdb | grep ${PDB} > ${PDB}_solo.pdb

echo "dir: $ITERATION prepped."
progress_check
cd ../
}


function mol2_gen {
cd $ITERATION
# run antechamber to gen mol2 prep/lib file
antechamber \
    -i ${PDB}.pdb           `# input pdb file` \
    -fi pdb                 `# input file format` \
    -o ${PDB}.mol2          `# output mol2 file(tleap compatible)` \
    -fo mol2                `# output file format` \
    -c bcc                  `# charge method = AM1-BCC` \
    -nc 0                   `# net charge` \
    -s 2                    `# verbose output option` \
    -m 1                    `# multiplicity (2S+1)` \
    -j 4                    `# use atom and part bond type prediction` \
    -at amber               `# atomtype: amber formatting` \
    -pf y &&                `# remove intermediate files`

# for W4F, first N atom is of atom type DU and should be N
# the terminal C should not be CZ atom type
sed -i 's/DU  /N   /' ${PDB}.mol2 &&
sed -i 's/CZ  /C   /' ${PDB}.mol2 &&

echo "${PDB}.mol2 file generated."
echo "Adjust AT in mol2 file to match ff15ipq lib AT."
progress_check
cd ../
}

function frcmod_gen {
cd $ITERATION
# run parmchk2 to generate frcmod parameter file from mol2 file
parmchk2 \
    -i ${PDB}.mol2          `# input file` \
    -f mol2                 `# input file formatting` \
    -o ${PDB}.frcmod        `# output frcmod file` \
    -p $AMBERHOME/dat/leap/parm/parm15ipq_10.3.dat

echo "${PDB}.frcmod file generated."
echo "Only F parameters are needed once AT updated to ff15ipq style naming."
progress_check
cd ../
}

function lib_gen {
cd $ITERATION
# generate tleap input file for solo AA lib file
# potentially don't need gaff file for this step
cat << EOF > tleap_lib.in
source leaprc.protein.ff15ipq
loadAmberParams ${PDB}.frcmod
${PDB} = loadmol2 ${PDB}.mol2
check ${PDB}
saveOff ${PDB} ${PDB}.lib
quit
EOF

tleap -f tleap_lib.in > tleap_lib.out
echo "${PDB} lib file generated, connections and res type may need to be manually fixed."
progress_check
cd ../
}


function pdb_vacuo_gen {
cd $ITERATION
# tleap input for capped dipeptide vacuo files
cat << EOF > tleap_vacuo.in
source leaprc.protein.ff15ipq
loadoff ${PDB}.lib
loadAmberParams ${PDB}.frcmod
${PDB} = sequence { ACE ${PDB} NME }
check ${PDB}
set ${PDB} box {32.006 32.006 32.006}
saveAmberParm ${PDB} ${PDB}_V.top ${PDB}_V.crd
savepdb ${PDB} ${PDB}_V.pdb
quit
EOF

tleap -f tleap_vacuo.in > tleap_vacuo.out
echo "in vacuo top/crd/pdb files generated for ${PDB} dipeptide."
progress_check
cd ../
}


function in_vacuo_min {
cd $ITERATION

# unrestrained in vacuo 10000 step minimization (500 SD)
pmemd -O -i ../../amber/2_min.in -o 2_min.out \
-p ${PDB}_V.top -c ${PDB}_V.crd -r ${PDB}_V.rst &&

echo "in vacuo min finished. Make sure mdgx iat values are correct before gen_conf step."
progress_check
cd ../ 
}


function gen_confs_mdgx {
cd $ITERATION
# TODO: add iat/phipsi var for gridsample
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
progress_check
cd ../../
}


#stage1_file_setup

#mol2_gen

#frcmod_gen

#lib_gen

#pdb_vacuo_gen

#in_vacuo_min

gen_confs_mdgx



