#!/bin/bash
# write scripts to visualize the generated conformations from script 1
# this is a good check to make sure that your structure is well sampled
#
# currently, there are functions to do this in Chimera or ChimeraX
#
# if you figure out a script to use a different program
# please submit a PR and I can add it in!

ITERATION=gaff_01
PDB=mon

function chimera_view {
    # go to where the conformer pdbs are
    cd $ITERATIONATION/GenConformers

    # write a chimera cmd script for pdb visualization
    CMD="open */*.pdb \n"
    for CONF in {1..19}; do    
        CMD="$CMD match #${CONF}:$(echo $PDB | tr '[a-z]' '[A-Z]') #0:$(echo $PDB | tr '[a-z]' '[A-Z]') \n"
    done
    CMD="$CMD center #0:$(echo $PDB | tr '[a-z]' '[A-Z]')"

    # write to file
    echo -e "$CMD" > chimera.cmd
    
    # run chimera with the cmd script
    chimera chimera.cmd
}

function chimerax_view {
    # go to where the conformer pdbs are
    cd $ITERATION/GenConformers

    # write a chimera cmd script for pdb visualization
    CMD="open */*.pdb \n"
    for CONF in {2..20}; do    
        CMD="$CMD align #${CONF}:$(echo $PDB | tr '[a-z]' '[A-Z]') to #1:$(echo $PDB | tr '[a-z]' '[A-Z]') \n"
    done
    CMD="$CMD ~display :WAT \n" 
    CMD="$CMD view #1:$(echo $PDB | tr '[a-z]' '[A-Z]') \n"
    CMD="$CMD lighting soft \n"
    CMD="$CMD graphics silhouettes true width 2 \n"
    CMD="$CMD set bgColor white"
    

    # write to file
    echo -e "$CMD" > chimerax.cxc
    
    # run chimera with the cmd script
    #chimerax --cmd "open chimerax.cxc"
    chimerax chimerax.cxc
}

function vmd_view {
    # go to where the conformer pdbs are
    cd $ITERATION/GenConformers

    # build tcl script
    # begin loop for all other confs
    CMD="for {set a 1} {\$a < 21} {incr a} { \n"
    CMD="$CMD mol new Conf\${a}/Conf\${a}.pdb \n"
    # delete default rep
    CMD="$CMD mol delrep 0 top \n"
    # build new licorice rep at a + 1 molecule index
    CMD="$CMD set index [ expr \$a -1 ] \n"
    CMD="$CMD mol selection all not water \n"
    CMD="$CMD mol rep Licorice 0.2 50 50 \n"
    CMD="$CMD mol addrep \$index \n"
    # align to conf 1 at index 0 
    CMD="$CMD set sel0 [atomselect 0 \"all not water\"] \n"
    CMD="$CMD set sel1 [atomselect \$index \"all not water\"] \n"
    CMD="$CMD set M [measure fit \$sel1 \$sel0] \n"
    CMD="$CMD \$sel1 move \$M \n"
    CMD="$CMD } \n"
    # some display settings
    CMD="$CMD axes location off \n"
    CMD="$CMD color Display Background white \n"
    CMD="$CMD display antialias on"

    # write to file
    echo -e "$CMD" > vmd.tcl

    vmd -e vmd.tcl
}


#chimera_view
#chimerax_view
vmd_view
