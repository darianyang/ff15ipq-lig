## Deriving Implicitly Polarized Charges

### The workflow for the ipq charge derivation process is as follows:

*Note that each script will need to be slightly adjusted or have some variables set for your particular small molecule system.*

#### Script 0
* Edit then run script 0, which generates the initial parameters for the molecule using AM1-BCC charges and an frcmod file with terms that were not available in the parent ff15ipq force field
    * `$ bash 0.0.ipq_initial_lib_frcmod.sh`
    * The charges are from the antechamber program
        * antechamber also handles atom types, which is currently set to use gaff
            * if you don't use gaff, new atom types may be needed
    * The frcmod file is from the parmchk2 program
        * currently this uses gaff parameters
            * if you don't use gaff, the frcmod file will need to be filled out with initial guesses for the zero values not found in the parameter file

#### Script 1
* Then edit and run script 1, this will generate the conformations that will be subjected to QM ESP grid calculations
    * There are 2 ways available to do this:
        * you can use high temperature (450K) simulations and save MD snapshots as the conformations
            * `$ sbatch 1.0.ipq_gen_conf_highT_equil.slurm`
        * or you can use the mdgx `&configs` module, which has alot of options in terms of restraining your molecule at user-specified atoms (make sure to customize this for your system)
            * `$ sbatch 1.0.ipq_gen_conf_mdgx_equil.slurm`
    * Both conformation generation scripts will also:
        * output a set of pdb files for each conformation, which can more easily visualized in vmd or a similar program
        * output a coordinate file (crd or rst)
        * minimize and equilibrate each individual conformation with positional restraints
* Before moving on, check to make sure your conformations are diverse and relevent:
    * Edit and run script 1.5 to visualize all conformations in chimera or chimerax
        * `$ bash 1.5.visualize_conf.sh` 
        * note that you should have chimera and/or chimerax as part of you PATH for this to run
            * e.g. for mac : `export PATH="$PATH:/Applications/Chimera.app/Contents/MacOS"`
            * for linux : `export PATH="$PATH:/home/USER/.local/UCSF-Chimera64-1.15rc/bin"`

#### Script 2 
* Now it's time to use script 2 to get the ESP grids in both explicit solvent and in vacuum for each conformation
* This is all done with mdgx, but the user must provide the `&ipolq` settings, including the path to a qm calculation program such as orca or gaussian
    * These are adjusted in the `2.0.ipq_qm_single_conf_setup.sh` file, which is copied and ran in each conformation directory by running the `2.0.ipq_qm_multi_conf_run.sh` file
        * note that for now, orca 5.0 works serially with amber 18 or 20
            * I'm not certain why, but running orca 5.0 in parallel is problematic with the current version of mdgx from amber 18 or 20
        * if you need to run in parallel, try using an older version of orca
            * for example: orca 3.0.3 works in parallel
            * note that these could be cluster specific issues (I'm using H2P at the University of Pittsburgh CRC)
* For monastrol (36 atoms), `MP2/cc-pVTZ` requires 114Gb+ for the MP2 module
    * If the RI approximation is used, this reduces to 300Mb
        * `RI-MP2 cc-pVTZ cc-pCTZ/C` : 1 conformation takes about 5-7 hours with 6/8Gb
    * Attempting `MP2/cc-pVTZ` with various memory requirements:
            * 120/152Gb : Ran out after 5 hours
            * 152/168Gb : Ran out after 6.5 hours
            * 184/184Gb : Ran out after 8 hours
            * 208/216Gb : Ran out after 11 hours
* After script 2 finishes, you can check to make sure that the qm_output files looks appropriate using script 2.5:
    * `$ bash 2.5.check_completion.sh`
    * If any of your conformations failed, you can resubmit then by running:
        * `$ bash 2.5.check_completion.sh resub`

#### Script 3
* Now that the grid files are generated, they are all taken into a single restrained electrostatic potential (RESP) fitting procedure
    * edit then run script 3: `$ bash 3.0.resp_fitting.sh`
    * you do not need to edit the `3.1.check_converge.py` script or run it, script 3.0 will take care of it
* There is some important adjustments to consider here which are all detailed in script 3 under the `&fitq` module of mdgx
    * This includes bond equivalencies (degeneracies) and restraints on buried atoms (putting the R in RESP fitting)
* After fitting new charges, this script will run the `3.check_convergence.py` script to see how close or far away you are from reaching a self-consistent IPolQ charge set
    * If you saveoff an updated mol2 file using tleap and the new library file, you can also visualize the atomic charge values with a program such as ChimeraX and maybe Avogadro
        * or just generate an updated topology file and open it up in VMD
    * If they are similar (within 10% difference), congrats! You've now got a self-consistent set of charges for your small molecule
        * if not, then you'll have to derive another set using your current charges as the starting point

#### Next Steps
* Now you can take the ipq solvent-vacuum averaged atomic partial charges from the resp fitting output and replace your AM1-BCC charges in the library file
    * I usually do this using vim: `ctrl + v` then select and yank (`y`), then open existing file (`:e lib_file`) and paste (`p` or `P`)
* After this, you may have to ITERATE and run this process again from script 0 with your updated charges
    * If you do, only run the first function for stage1_file_setup since you already have the other files
        * this can be adjusted by commenting out the other functions at the bottom of script 0
* Once they're converged, take this self-consistent set of ipq charges and move on to the bonded parameter derivation stage (`../bonded/`)

<br>
  
---
#### Extra notes for Script 2 with MP2
* If you're running MP2 calculations (before you run all conformations), it is important to adjust and optimize for the amount of memory you may need:
    * set the %maxcore keyword in `&ipolq` to 75% of the physical memory available
        * so if you have this set to 6000 (6 Gb), then request 8 Gb of memory with slurm
        * note that the %maxcore is the "max" memory per CPU core, which orca recommends to be 75% of the actual memory available since orca may use more than the maxcore setting allows
            * so if you set `maxcore=2000` (2 Gb) and run on 4 CPUs, make sure each CPU has access to 2 Gb of memory + 25% (as per orca recommendation)
                * thus the total memory requested would be 10 Gb
        * if your run fails due to a "not enough memory" error, check the qm output file which will tell you at what point it failed and how much memory was allocated vs actually needed
* I would recommend testing the mdgx `&ipolq` module first for a single conformation using a smaller simulation step limit and a faster level of QM theory/smaller basis set
    * e.g. `HF/STO-3G`; or something like `RI-MP2 def2-TZVP def2-TZVP/C RIJK def2/JK`, which has density fitting approximations for MP2 and for the HF SCF Coulomb and HF exchange integrals
    * An example of my tests are available in `v00/GenConformers/conf1-test`
        * adjust the `ipq_qm_mp2_grid_gen_test.mdgx` or the `2.0.ipq_qm_single_conf_setup` script and run the `conf_1_mdgx_grid_gen.slurm` file (I usually test this on an interactive session)
