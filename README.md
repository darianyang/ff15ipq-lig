# Scripts for ff15ipq ligand parameter derivation

This directory provides an example of how to derive ff15ipq compatible parameters for a monastrol small molecule using slurm based HPC resources.

Dependencies:
* AmberTools
* ORCA

The workflow is as follows:
* generate a mol2 file of your small molecule or ligand
    * this can be done using something like Avogadro
* derive a set of implicitly polarized (ipq) atomic partial charges for your molecule
    * see the /charges directory
* optimize the initial set of bonded force field parameters that were roughly estimated in the charge derivation step
    * this is done *in vacuo* and uses the finalized vacuum phase atomic charges
    * see the /bonded directory
* you will now have an finalized library file containing the atomic charges and a frcmod file containing the bonded parameters for your molecule of interest
    * load these files into tleap along with the ff15ipq force field and you're good to go! 
