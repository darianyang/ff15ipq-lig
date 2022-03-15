"""
Take multiple PDB files and build then plot the RMSD matrix.

I wrote this script originally in 2020, it's kinda clunky and I think 
it could use some work, but for now it gets the job done.

Just fill out the ITERATION variable first and run in a Python env with:
    MDAnalysis
    matplotlib
    numpy
    pandas
    seaborn
"""
import numpy as np
import pandas as pd
import seaborn as sns
import MDAnalysis as mda

from pathlib import Path
from MDAnalysis.analysis import rms
from matplotlib import pyplot as plt

ITERATION = 'gaff_01'

# make list of target pdb paths, then load these on the fly for rmsd calc
pdb_paths = []
for pdb in range(1,21):
    pdb_paths.append(f"{ITERATION}/GenConformers/Conf{pdb}/Conf{pdb}.pdb")

def rmsd_diff_calc(pdb, ref_pdb):
    """
    Take two pdb file path strings, allign and return rmsd value in Angstroms.
    Selects resid 1, which should be just the small molecule of interest.
    """
    protein = mda.Universe(Path(pdb))
    protein_ref = mda.Universe(Path(ref_pdb))

    # calc non-termini heavy atom rmsd of 2kod
    rmsd = rms.rmsd(protein.select_atoms('resid 1').positions,
                    protein_ref.select_atoms('resid 1').positions,  
                    center=True,
                    superposition=True)
    return rmsd

def build_pdb_rmsd_matrix(pdb_paths, pdb_diff_path=None):
    """
    Returns rmsd difference matrix for multiple pdb files.
    Returns rmsd_list (3-item list), pdb_comp_amount (int).
    Optional with pdb_diff_path return pdb_diff_comp(int).
    """
    # make 3 column list or ndarray for x, y = (pdb1-n * pdb1-n) and z = rmsd diff
    rmsd_list = [[], [], []]

    # get rmsd difference between each pdb file in nested loop and append
    for pdb0 in pdb_paths:

        # compare 2 different sets of pdb files
        if pdb_diff_path != None:
            for pdb1 in pdb_diff_path:
                # append to x (col 0) pdb in outer loop
                rmsd_list[0].append(pdb_paths.index(pdb0) + 1)
                # append to y (col 1) pdb in inner loop
                rmsd_list[1].append(pdb_diff_path.index(pdb1) + 1)
                
                # find and append to z (col 2) rmsd value between pdb0 and pdb1
                rmsd = rmsd_diff_calc(pdb0, pdb1)
                #print(f"\n    For PDB-A = {pdb0} and PDB-B = {pdb1} : RMSD = {rmsd}")
                rmsd_list[2].append(rmsd)

        elif pdb_diff_path == None:
            # here using same pdb_paths
            for pdb1 in pdb_paths:
                # append to x (col 0) pdb in outer loop
                rmsd_list[0].append(pdb_paths.index(pdb0) + 1)
                # append to y (col 1) pdb in inner loop
                rmsd_list[1].append(pdb_paths.index(pdb1) + 1)
                
                # find and append to z (col 2) rmsd value between pdb0 and pdb1
                rmsd = rmsd_diff_calc(pdb0, pdb1) 
                rmsd_list[2].append(rmsd)

    # amount of pdb files to compare to each other
    pdb_comp_amount = len(pdb_paths)

    if pdb_diff_path == None:
        return rmsd_list, pdb_comp_amount
    elif pdb_diff_path !=None:
        pdb_diff_comp = len(pdb_diff_path)
        return rmsd_list, pdb_comp_amount, pdb_diff_comp

def plot_pdb_rmsd_matrix(rmsd_list, pdb_amount, pdb_diff_amount=None, xylabels=None):
    """
    Generate and plot heatmap of rmsd matrix from list: x*y=pdb z=rmsd. 
    """
    # need to properly format data and build heatmap using numpy
    # tutorials online: e.g. https://blog.quantinsti.com/creating-heatmap-using-python-seaborn/

    # TODO: these can't be the same
    x_name = ' ' 
    y_name = '  '

    # build pandas df
    df = pd.DataFrame(rmsd_list).transpose()
    df.columns = [x_name, y_name, 'rmsd']
    #print(df)

    # TODO: perhaps some adjustment of row and col labels to better match

    # made matrix size dynamic as the len of pdb_path list
    # TODO: I can just use int(np.sqrt(len(df))) as shape
    if pdb_diff_amount == None:
        rmsd_matrix = np.asarray(df['rmsd']).reshape(pdb_amount, pdb_amount)
    elif pdb_diff_amount != None:
        rmsd_matrix = np.asarray(df['rmsd']).reshape(pdb_amount, pdb_diff_amount)
    rmsd_df = df.pivot(index=y_name, columns=x_name, values='rmsd')
    #print(rmsd_df)

    fig, ax = plt.subplots(figsize=(6,4))
    if xylabels:
        sns.heatmap(rmsd_df, cmap='viridis', cbar_kws={'label': r'RMSD ($\AA$)'}, 
                    xticklabels=xylabels, yticklabels=xylabels)
    else:
        sns.heatmap(rmsd_df, cmap='viridis', cbar_kws={'label': r'RMSD ($\AA$)'})
    #plt.imshow(rmsd_df, cmap='viridis')
    #plt.pcolor(rmsd_df, cmap='viridis')
    #plt.xlim(1,100)
    #plt.xticks(rmsd_df.columns)
    #ax.set_xticks([str(x) for x in rmsd_df.columns])
    #plt.ylim(0,100)
    #plt.yticks(np.arange(1, 20, 1))
    #plt.colorbar(label=r'RMSD ($\AA$)')
    
    # plt.tight_layout()
    # #plt.show()
    # plt.savefig('figures/we_dist_c2_clust_rmsd_1-75_39.png', dpi=300)

plt.rcParams.update({'font.size': 14})
plt.rcParams["figure.titleweight"] = "bold"
plt.rcParams["font.weight"] = "bold"
plt.rcParams["axes.labelweight"] = "bold"

# subset of comparison matrix
rmsd_list, pdb_comp_amount = build_pdb_rmsd_matrix(pdb_paths)
plot_pdb_rmsd_matrix(rmsd_list, pdb_comp_amount)

plt.title(f"{ITERATION} Conformers", fontweight="bold")
plt.xticks(rotation=45, ha="right")
plt.tight_layout()
#plt.show()
plt.savefig(f"{ITERATION}_conformer_rmsd.png", dpi=300, transparent=True)
