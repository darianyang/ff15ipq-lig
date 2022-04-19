#!/bin/env python
# get |E(qm) - E(mm)| data from mdgx report.m parameter fitting report

import numpy as np
import matplotlib.pyplot as plt


def load_report(report, res=None):
    """
    Read and process report.m data.
    """
    with open(str(report)) as f:
         lines = f.readlines()
    
    # isolate a single res class before converting to array
    if res:
        data = [line[:42] for line in lines 
                if line.startswith(" ") and line[42] == "%" and line[44:47] == str(res)] 
    else:
        # only keep rows with E(mm) and E(qm) data for all datasets
        data = [line[:42] for line in lines 
                if line.startswith("-") and line[42] == "%"]

    # columns are: qm_target, mm_original, mm_fitted, error
    return np.loadtxt(data)

def calc_abs_error(data):
    # |E(qm) - E(mm)| = |Error|
    return np.abs(np.subtract(data[:,0], data[:,2]))
def calc_rmse(data):
    # error is in column 3 of data array
    return np.sqrt(np.mean(np.square(calc_abs_error(data))))

def energy_plot(data):
    """
    Plot the QM vs MM energy of each conformation.
    """
    qm_target = data[:,0]
    mm_original = data[:,1]
    mm_fitted = data[:,2]

    # TODO: calc RMSE to put on label
    #og_rmse = calc_rmse(data)
    #fit_rmse = calc_rmse(data)

    fig, ax = plt.subplots(figsize=(5,4))
    # TODO: calc RMSE from report or grab from fit.out
    ax.scatter(qm_target, mm_original, c='k', s=4, label="Original (RMSE = 2.25 kcal/mol)")
    ax.scatter(qm_target, mm_fitted, c='r', s=4, label="Fitted (RMSE = 2.19 kcal/mol)")
    
    # draw diagonal line
    ax.plot([0, 1], [0, 1], transform=ax.transAxes, linestyle="--", color="grey")

    # xy limits and labels
    lims = (-150, -110)
    ax.set_ylim(lims)
    ax.set_xlim(lims)
    ax.set_ylabel('Model Energy (kcal/mol)',size=12)
    ax.set_xlabel('Target Energy (kcal/mol)',size=12)

    ax.grid(True)
    ax.legend(prop={'size': 8}, markerscale=2, loc="lower right")
    fig.tight_layout()
    fig.savefig("mon_v01_g1.pdf")
    plt.show()

# plot for a single system
rep = load_report("v01/report.m")
energy_plot(rep)

def violin_plot(report, res_classes):
    import pandas as pd 
    import seaborn as sns

    #plt.rcParams['figure.figsize']= (7.5,5.5)
    #plt.rcParams['figure.figsize']= (8,5) # poster, xlabelpad=9
    plt.rcParams.update({'font.size': 18})
    plt.rcParams["font.family"]="Sans-serif"
    #plt.rcParams["font.serif"]="Helvetica World"
    plt.rcParams['font.sans-serif'] = 'Dejavu Sans'
    plt.rcParams['mathtext.default'] = 'regular'
    plt.rcParams['axes.linewidth'] = 2.5

    # |E(qm) - E(mm)| = |Error|
    df = pd.DataFrame([calc_abs_error(load_report(report, res)) for res in res_classes]).transpose()
    dx = pd.DataFrame([calc_rmse(load_report(report, res)) for res in res_classes]).transpose()

    fig, ax = plt.subplots()
    ax.set_ylim(0,5)
   
    res_colors = ['#59C26E', '#59C26E', '#59C26E', '#59C26E', '#E84A52', '#E84A52', '#5FA2FA', '#5FA2FA']
    a = sns.violinplot(data=df, linestyle='-', linewidth=3, cut=0, inner="quartile", jitter=False, 
                       bw=0.5, figsize=(10,8), scale="width", width=0.8, ax=ax, palette=res_colors)

    sns.swarmplot(data=dx, color='w', size=15, ax=ax)
    ax.set_axisbelow(True)
    ax.yaxis.grid(alpha=0.5, linestyle='-')
    ax.tick_params(width=2.5, length=6)
    ax.tick_params(axis='x', bottom=False)

    plt.setp(a.collections, edgecolor="k")

    a.set_xticklabels(res_classes)
    a.set_xlabel('Residues', fontweight='bold', labelpad=12)
    a.set_ylabel(r'|U$_Q$$_M$-U$_M$$_M$|' + '\n' + '(kcal/mol)', fontweight='bold', labelpad=16)

    ### patch style: allows for border
    import matplotlib.patches 
    def add_patch(recx, recy, facecolor, text, recwidth=0.04, recheight=0.06, recspace=0):
        ax.add_patch(matplotlib.patches.Rectangle((recx, recy), 
                                                  recwidth, recheight, 
                                                  facecolor=facecolor,
                                                  edgecolor='black',
                                                  clip_on=False,
                                                  transform=ax.transAxes,
                                                  lw=2.25)
                     )
        ax.text(recx + recheight + recspace, recy + recheight / 2, text, ha='left', va='center',
                transform=ax.transAxes)
    recy = -0.34
    space = 0.0
    origin = 0.1
    rec_space = 0.3
    add_patch(origin, recy, '#59C26E', '$^{19}$F-Trp', recspace=space)
    add_patch(origin + rec_space, recy, '#E84A52', '$^{19}$F-Tyr', recspace=space)
    add_patch(origin + rec_space * 2, recy, '#5FA2FA', '$^{19}$F-Phe', recspace=space)

    for l in a.lines: 
        l.set_linestyle('-')
        l.set_linewidth(2.5)
        l.set_color('black')
        l.set_alpha(1)
        
    plt.tight_layout()
    plt.show()
    #plt.savefig('V01/violin_4sigtol_10cpl_V01_poster.pdf', dpi=600, bbox_inches='tight', transparent=True)


#res_classes = ["W4F", "W5F", "W6F", "W7F", "Y3F", "YDF", "F4F", "FTF"]
#violin_plot("V01/report_final.m", res_classes)

#for res in res_classes:
#    print(res, calc_rmse(load_report("V01/report_final.m", res)))

