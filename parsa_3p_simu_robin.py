#!/home/jgeng/.conda/envs/research/bin/python
##!/opt/anaconda3/bin/python

import sys
sys.path.append('~/bin/') # where infoSet is located
import infoSetRobin
import pandas as pd
import numpy as np
import math
from tabulate import tabulate
import matplotlib.pyplot as plt
import subprocess








if __name__ == '__main__':

    if len(sys.argv)!=2:
        print ("    Usage:", str(sys.argv[0]).split('/')[-1], "config.txt")
        print ("    Run 3-period backtest based on the parameters in config.txt file(sample: ~/bin/config.txt.3p).")
        print ("    Results in raw.csv and overview.csv")
        sys.exit()


    config_path = sys.argv[1]

    pd.set_option('display.max_columns', None)

    # reading config file
    configuration = pd.read_csv(config_path, sep=" = ", header=None,
                                index_col=0, engine='python').transpose()
    #print(configuration)
    info = infoSetRobin.Col(configuration)
    df = info.df
    msg = info.prin()

    msg.append(' ')
    msg.append(' ')
    msg.append("Overall:")
    msg.append(infoSetRobin.Port(info).ret())

    la = {"Opt": [info.opt]}
    la["Priority"] = [info.priority]
    #la["Tcost"] = [info.tcost]
    y = tabulate(la, headers="keys", tablefmt='orgtbl')
    msg.insert(2, y)

    for i in msg:
        print (i)

    # this is raw pos/pnl file
    info.cdf = info.cdf.round(7) #keep 7 digits 
    info.cdf.to_csv("raw.csv",index=False,sep=" ") # indexFalse is not to output row index

    # this is summary stats file
    a = infoSetRobin.Port(info).ovr()
    a['Priority'] = info.priority
    a['Opt'] = info.opt
    #a['Tcost'] = info.tcost
    a['Minute'] = info.minute
    a.to_csv("overview.csv",index=False,sep=" ")


    sys.exit(0) # like __END__ in perl
  



    '''
    df = info.cdf
    plt.scatter(df.bt1DMV9,df.pos0, s=2, label='adjusted')
    plt.title('Fig3, Opt_Za')
    plt.xlabel('Forecast')
    plt.ylabel('Position')

    plt.show()
    
    x1 = info.cdf.pos0

    y1 = info.cdf.bt1DMV9
    x2 = opt_xt(y1, 0.07)
    matp.scatter(y1,x1, s=2, label='adjusted')
    matp.scatter(y1,x2, s=1, label='original')
    matp.plot([-0.3,0.3], [-0.3,0.3],'k-', lw=1)
    matp.legend(bbox_to_anchor=(0., 1.02, 1., .102), loc=3,
               ncol=2, mode="expand", borderaxespad=0.)
    matp.title('X = 0.07, P = 0.4')
    matp.show()
    '''
