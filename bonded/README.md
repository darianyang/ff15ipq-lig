## These files are still in development
---
## Deriving Bonded IPolQ Force Field Parameters

### The workflow for the bonded parameter derivation process is as follows:

*Note that here I am only adjusting the dihedrals and not the angle or bonded parameters, which are taken from GAFF. The thought behind this is that the torsion adjustments will implicitly account for any discrepancies in the charge model with other bonded parameters; however, you may include angle and bonded parameters in your fitting procedure, if you so choose. See the Amber manual mdgx section or the ipq parameter tutorials for more information on how to do this.*
 
*Also, remember to edit and tailor each script to your system before use.*

#### Script 0
* This script will take an initial pdb file and will set up your initial iteration directory as well as generate n conformations of the pdb file
* These conformations will then be used to fit your parameters in the later scripts.
* This is a really important step, especially since you will have to define in the `&configs` module of mdgx how to generate the conformations.
    * For example, I rotated about select flexible dihedrals in monastrol using a force constant of 32 kcal/mol
* Check the output file named "GenConformers.out" for more details about the conformations generated

#### Script 1
* This script goes through each of the conformations and runs orca single point energy (SPE) calculations
* Depending on how many conformations you have, see the bottom of the script for optimization options
    * Specifically, you'll want to have each slurm job handle n conformations where the amount of CPUs requested can evenly split the conformations
        * e.g. I have 1000 conformations so I ran 10 slurm jobs with 20 CPU each
            * each job will run 20 CPUs 5 times for a total of 1000 conformations
* Note that this script must be ran using the orca 4.2.0 settings, with orca 5.0.0, script 3 does not recognize the orca output (this is likely a bug that mdgx has not caught up to yet since orca 5 is relatively recent)

#### Script 2
* This script will then go through and run error checking on all of the orca output files for each conformation
* If the output looks okay, the energies are extracted and placed into a concatenated file 
* All of the molecule conformations are also concatenated into a single ncdf trajectory file
* These two files are needed for script 3 (bonded parameter fitting)

#### Script 3
* Now it's time to fit your desired bonded parameters in terms of their MM energies to the QM energies that we just calculated for each conformation.
* Just take all of the terms that you would like to fit and include them in the `&param` module of mdgx in script 3
* One change I made here is that I am using a harmonic restraint of 0.002 kcal/mol instead of the value from the tutorial of 0.0002 kcal/mol
    * This allows for less deviation from the original values
    * Feel free to try it with different restraint values, but I found that, with the lower value, the new parameters seem to be overfit and the final results went againt chemical intuition
* The FIT.out file will contain the information about the LLS fitting procedure and the overall changes in RMSE (kcal/mol)
* The FIT.frcmod file is the new frcmod file with the newly fit parameters
* The report.m file is a data file containing all the QM and MM energies for each conformation
    * This is useful to plot, and can be done directly in Matlab by opening the report.m file or using the `plot_fit_report.py` script if you don't have Matlab

#### Scripts 4-7
* These scripts are optional if you want to run "generation 2" fitting of the bonded parameters
* From the tutorial, this is the rationale:
    * The parameters were trained on data that thoroughly covers their space, but we don't know quite how well the parameters will do when manipulating the molecule on their own. Even though they are individually well sampled, they could conspire to create artificial minima. We need to let them guide a new round of conformational search, in the absence of restraints, and then see whether those minima they find remain in agreement with our benchmark QM calculations.
* They are essentially the same as scripts 0-3 but using the conformations already generated
* If you prefer not to run these steps, skip directly to script 8

#### Script 8
* This script simply sets up the next iteration
* Make sure to specify whether you are using the gen2 scripts

#### Next
* After running script 8, you should be able to just run everything again from script 0 without changing anything.
* Of course you should probably check just in case, but I think it should be good to go
* Keep going until the RMSE values are roughly converged to < 1% between the iterations

#### Done!
* Okay, now you're finished deriving the bonded parameters for your system!
* To use them in simulations, just load them up in tleap with gaff and ff15ipq 

