## Deriving Implicitly Polarized Charges

### The workflow for the ipq charge derivation process is as follows:

#### Script 0
* First run script 0, which generates the initial parameters for the molecule using AM1-BCC charges and an frcmod file with terms that were not available in the parent ff15ipq force field
    * The charges are from the antechamber program
    * The frcmod file is from the parmchk2 program
        * this file needs to be filled out with initial guesses for the zero values

#### Script 1
* Then run script 1, this will generate the conformations that will be subjected to QM ESP grid calculations
    * There are 2 ways available to do this:
        * you can use high temperature (450K) simulations and save MD snapshots as the conformations
        * TODO - update : or you can use the mdgx &configs module, which has alot of options in terms of restraining your molecule at user-specified atoms
    * Both conformation generation scripts will also then minimize and equilibrate each individual conformation with positional restraints

#### Script 2 
* Now it's time to use script 2 to get the ESP grids in both explicit solvent and in vacuum for each conformation
* This is all done with mdgx, but the user must provide the &ipolq settings, including the path to a qm calculation program such as orca or gaussian
    * These are adjusted in the 2.ipq_qm_single_conf_setup.sh file, which is copied and ran in each conformation directory by the 2.ipq_qm_multi_conf_run.sh file
        * note that for now, orca 5.0 works serially with amber 18 or 20
            * I'm not certain why, but running orca 5.0 in parallel is problematic with the current version of mdgx from amber 18 or 20
        * if you need to run in parallel, try using an older version of orca
            * for example: orca 3.0.3 works in parallel
            * note that these could be cluster specific issues (I'm using H2P at the University of Pittsburgh CRC)
    * If you're running MP2 calculations, it is important to consider and adjust for the amount of memory you may need:
        * before you run all conformations: optimize the memory allocations
        * set the %maxcore keyword in &ipolq to 75% of the physical memory available
            * so if you have this set to 6000 (6 Gb), then request 8 Gb of memory with slurm
            * note that the %maxcore is the "max" memory per CPU core, which orca recommends to be 75% of the actual memory available since orca may use more than the maxcore setting allows
                * so if you set %maxcore=2000 (2 Gb) and run on 4 CPUs, make sure each CPU has access to 2 Gb of memory + 25% (per orca recommendation), so total memory requested would be 10 Gb
        * if your run fails due to a "not enough memory" error, check the qm output file which will tell you at what point it failed and how much memory was allocated vs actually needed
* I would recommend testing the mdgx &ipolq module first for a single conformation using a smaller simulation step limit and a faster level of QM theory/smaller basis set
    * e.g. HF/STO-3G; or something like RI-MP2 def2-TZVP def2-TZVP/C RIJK def2/JK, which has density fitting approximations for MP2 and for the HF SCF Coulomb and HF exchange integrals
    * An example of my tests are available in v00/GenConformers/conf1-test
        * adjust the ipq_qm_mp2_grid_gen_test.mdgx script and run the conf_1_mdgx_grid_gen.slurm file (I usually test this on an interactive session)

#### Script 3
* Now that the grid files are generated, they are all taken into a single restrained electrostatic potential (RESP) fitting procedure
* There is some important adjustments to consider here which are all detailed in script 3 under the &fitq module of mdgx (TODO for monastrol)
