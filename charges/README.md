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

#### Script 2 : TODO (ORCA5.0)
* Now it's time to use script 2 to get the ESP grids in both explicit solvent and in vacuum for each conformation
* This is all done with mdgx, but the user must provide the &ipolq settings, including the path to a qm calculation program such as orca or gaussian
    * These are adjusted in the 2.ipq_qm_single_conf_setup.sh file, which is copied and ran in each conformation directory by the 2.ipq_qm_multi_conf_run.sh file

#### Script 3
* Now that the grid files are generated, they are all taken into a single restrained electrostatic potential (RESP) fitting procedure
* There is some important adjustments to consider here which are all detailed in script 3 under the &fitq module of mdgx (TODO for monastrol)
