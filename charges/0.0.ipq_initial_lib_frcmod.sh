#!/bin/bash
# pipeline for ipq style charge derivation for fluorinated amino acids
# this script is best run locally or with a crc-interactive session

######################################################################
# set variables: your PDB file from Avogadro should be $PDB.pdb

PDB=mon             # this should be your 3 letter PDB residue name
ITERATION=gaff_00   # this can be anything: all files will go here

# remember to adjust antechamber and parmchk2 arguments if needed
# currently, this workflow uses gaff atom types and parameter files
######################################################################

function progress_check {
echo -e "\nCheck output so far. Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
}

function stage1_file_setup {
### directory and file setup

mkdir -v $ITERATION
cp -v ${PDB}.pdb $ITERATION
cd $ITERATION

# edit pdb file: get rid of connecting lines, change HETATOM to ATOM
sed -i '/CONECT/d' ${PDB}.pdb
sed -i '/MASTER/d' ${PDB}.pdb
sed -i 's/HETATM/ATOM  /g' ${PDB}.pdb

# set the 3 letter id and name of the molecule (if not already set)
# with raw avogadro output, the values need to be set
sed -i "s/UNL/${PDB^^}/g" ${PDB}.pdb
sed -i "s/UNNAMED/${PDB}.pdb/" ${PDB}.pdb

echo -e "\nDir: $ITERATION prepped."
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
    -at gaff                `# atomtype formatting : can also be gaff or gaff2` \
    -pf y &&                `# remove intermediate files`

# for W4F, first N atom is of atom type DU and should be N
# the terminal C should not be CZ atom type
#sed -i 's/DU  /N   /' ${PDB}.mol2 &&
#sed -i 's/CZ  /C   /' ${PDB}.mol2 &&

echo -e "\n${PDB}.mol2 file generated.\n"
echo "Adjust AT in mol2 file to match ff15ipq lib AT."
echo "If there are any dummy atoms (DU) these atom types are not in ff15ipq"
echo "Update their AT name using something similar from parm15ipq_10.3.dat"
echo "Or use a new AT, but you must update PARMCHK.DAT"
echo -e "\nIf you're using GAFF, the above may not apply."
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
    -s 1                    `# use the gaff parm set`
#    -p $AMBERHOME/dat/leap/parm/parm15ipq_10.3.dat

echo -e "\n${PDB}.frcmod file generated.\n"
echo "Parameters with missing terms in ff15ipq will be set to zero."
echo "Fill these out with initial guess values based on similar atoms."
echo "Later on, these parameters will also be optimized." 
echo "Note that this is less of an issue with GAFF"
progress_check
cd ../
}

function lib_gen {
cd $ITERATION
# generate tleap input file for solo lib file
cat << EOF > tleap_lib.in
#source leaprc.protein.ff15ipq
source leaprc.gaff
loadAmberParams ${PDB}.frcmod
${PDB} = loadmol2 ${PDB}.mol2
check ${PDB}
saveOff ${PDB} ${PDB}.lib
quit
EOF

tleap -f tleap_lib.in > tleap_lib.out
echo -e "\n${PDB} lib file generated, connections and res type may need to be manually fixed."
echo "Note that unless you are working with a modified amino acid, connections is not needed."
echo "restype can be a 'p'rotein residue, 'n'ucleic acid residue, 'w'ater residue, or '?'unknown residue"
progress_check
cd ../
}

# for every iteration, run this function
stage1_file_setup

# only run these functions for the first iteration
# with subsequent iterations, you will have the updated files already
mol2_gen
frcmod_gen
lib_gen

