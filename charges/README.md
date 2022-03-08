## Deriving Implicitly Polarized Charges

The workflow for the ipq charge derivation process is as follows:
* First run script 0, which generates the initial parameters for the molecule using AM1-BCC charges and an frcmod file with terms that were not available in the parent ff15ipq force field
    * The charges are from the antechamber program
    * The frcmod file is from the parmchk2 program
        * this file needs to be filled out with initial guesses for the zero values

### TODO:
* potentially combine the next iter prep to stage 1 script
