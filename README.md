# Scripts for ff15ipq ligand parameter derivation

<p align="center">
    <img src="docs/ipq.png" alt="ipq" width="600">
</p>

This directory provides an example of how to derive ff15ipq compatible parameters for a monastrol small molecule using slurm based HPC resources.

Dependencies:
* AmberTools
* ORCA

The workflow is as follows:

<p align="center">
    <img src="docs/ipq_workflow.png" alt="ipq workflow" width="500">
</p>

* generate a mol2 file of your small molecule or ligand
    * this can be done using something like Avogadro
* derive a set of implicitly polarized (ipq) atomic partial charges for your molecule
    * see the /charges directory
* optimize the initial set of bonded force field parameters that were roughly estimated in the charge derivation step
    * this is done *in vacuo* and uses the finalized vacuum phase atomic charges
    * see the /bonded directory
* you will now have an finalized library file containing the atomic charges and a frcmod file containing the bonded parameters for your molecule of interest
    * load these files into tleap along with the ff15ipq force field and you're good to go! 

### See the following publications for more information about the ff15ipq protein force field:
* KT Debiec, DS Cerutti, LR Baker, AM Gronenborn, DA Case, and LT Chong. “Further along the road less traveled: AMBER ff15ipq, an original protein force field built on a self-consistent physical model.” J. Chem. Theory Comput. 2016, 12, 3926. https://doi.org/10.1021/acs.jctc.6b00567
* AT Bogetti, HE Piston, JMG Leung, CC Cabalteja, DT Yang, AJ DeGrave, KT Debiec, DS Cerutti, DA Case, WS Horne, and LT Chong. “A twist in the road less traveled: The AMBER ff15ipq-m force field for protein mimetics.” J. Chem. Phys. 2020, 153(6), 064101. https://doi.org/10.1063/5.0019054
* DT Yang, AM Gronenborn, and LT Chong. "Development and Validation of Fluorinated Amino Acid Parameters for use with the AMBER ff15ipq Protein Force Field", BioRxiv (2022) https://doi.org/10.1101/2022.01.06.475229
