"""
Check to see if a single small molecule set of charges is convereged after
a round of IPolQ charge derivation.

This only works for a single restype in the library and resp output files.

Parameters
----------
library : str
    sys.argv[1], the library file (OFF format) containing previous charges.
resp_out : str
    sys.argv[2], the mdgx resp &fitq output file containing new ipq charges.

Returns
-------
deviation : float
    The average percent deviation from the average absolute charge values.
    If this value is < 10%, you're in good shape to move on to next stage.
    Otherwise, run another round of IPolQ charge derivation until < 10%.

        Abs Charge Difference = |new charge value - old charge value|
        Average Abs Charge Value = < |All New Charge Values for the Iteration| >
        
        Percent Deviation from Average Iteration Charge Values = 
        ( Abs Charge Difference / Average Abs Charge Value ) * 100

        deviation = < Percent Deviation from Average Iteration Charge Values >
"""

import sys
import numpy as np

# initial args from CLI
library = sys.argv[1]
resp_out = sys.argv[2]

def grab_lib_charges(library):
    """
    Extract the charge values from a library file with 1 entry.
    Gets charge values between the first two !entry and !entry lines.
    """
    # open and read file
    with open(str(library)) as f:
        lines = f.readlines()
    
    charges = []
    # skip the header info and start at line 4
    for line in lines[3:]:
        # stop at the end of the charge table
        if line.startswith("!entry"):
            break
        # only include the charge value
        charges.append(line[len(line)-10:-1])

    # return a float ndarray
    return np.loadtxt(charges, dtype=float)

def grab_resp_charges(resp_out):
    """
    Extract the IPolQ charge values from the mdgx &fitq resp fitting output.
    """
    # open and read file
    with open(str(resp_out)) as f:
        lines = f.readlines()

    # get the dynamics starting point of charge table
    for line in lines:
        if line.startswith("(2.) Charges on all atoms"):
            start_index = lines.index(line)
            # offset to the first atom
            start_index += 5
    
    # make a list of the IPolQ charges
    charges = []
    for line in lines[start_index:]:
        # stop at end of charge table
        if line.startswith("<++>"):
            break
        # grab the rightmost IPolQ,pert column
        charges.append(line[len(line)-9:-1])
    
    # return a fload ndarray
    return np.loadtxt(charges, dtype=float)

def calc_percent_deviation(lib, resp):
    """
    Abs Charge Difference = |new charge value - old charge value|
    Average Abs Charge Value = < |All New Charge Values for the Iteration| >

    Percent Deviation from Average Iteration Charge Values =   
    ( Abs Charge Difference / Average Abs Charge Value ) * 100 

    Returns
    -------
    deviation : float
        < Percent Deviation from Average Iteration Charge Values >
    """
    abs_diff = np.abs(np.subtract(lib, resp))
    avg_abs_new_charge = np.average(np.abs(resp))
    print("\navg_abs_new_chage (eV): ", avg_abs_new_charge)

    deviation = np.divide(abs_diff, avg_abs_new_charge) * 100
    print("\nDeviation array (%): ", deviation)

    return np.average(deviation)

# test
#a = np.array([-0.27400, 0.13800, -0.05500])
#b = np.array([-0.47978, 0.30403, -0.07841])
#c = calc_percent_deviation(a, b)

if __name__ == "__main__":
    lib = grab_lib_charges(library)
    resp = grab_resp_charges(resp_out)
    deviation = calc_percent_deviation(lib, resp)
    print("\nOriginal charge set (eV): ", lib)
    print("New charge set (eV): ", resp)
    print(f"\nThe final percent deviation between the {library} \n" +
          f"and {resp_out} charge sets is {deviation:0.2f}%\n")
    if deviation < 10:
        print("\tNice! Now move on to bonded parameter derivation\n")
        print("Note that you will need to make a seperate library file of the vacuum phase")
        print(f"charges from the {resp_out} file to use for bonded parameter derivation.\n")
    elif deviation >= 10:
        print("\tI would recommend running another iteration until this value is < 10%\n")