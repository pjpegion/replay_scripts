import matplotlib
matplotlib.use('Agg')
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import rcParams
import sys


color1 = 'r'; linewidth1 = 1.0
color2 = 'b'; linewidth2 = 1.0

region = 'Global'
obtypes = 'All Insitu'
#obtypes = 'Sondes/Drops/Pibals'


expt1=sys.argv[1]
expt2=sys.argv[2]
date1=sys.argv[3]
date2=sys.argv[4]

strat = False; levtop=125; levbot=925
strat = False

# date range for title.
dates = '%s-%s' % (date1,date2)

rcParams['figure.subplot.left'] = 0.1 
rcParams['figure.subplot.top'] = 0.85 
rcParams['legend.fontsize']=12

levels = [] 
q_fit1 = []; q_fit2 = []
wind_fit1 = []; wind_fit2 = []
temp_fit1 = []; temp_fit2 = []
temp_bias1 = []; temp_bias2 = []
q_bias1 = []; q_bias2 = []
wind_count1 = []; wind_count2 = []
temp_count1 = []; temp_count2 = []
q_count1 = []; q_count2 = []
for line in open(expt1):
    if line.startswith('#'): continue
    linesplit = line.split()
    lev = int(float(linesplit[0]))
    if not strat and lev < levtop: continue
    if strat and lev > levtop: continue
    if lev > levbot: continue
    levels.append(lev)
    wind_count1.append(int(linesplit[1]))
    wind_fit1.append(float(linesplit[2]))
    temp_count1.append(int(linesplit[3]))
    temp_fit1.append(float(linesplit[4]))
    temp_bias1.append(float(linesplit[5]))
    q_count1.append(int(linesplit[6]))
    q_fit1.append(float(linesplit[7]))
    q_bias1.append(float(linesplit[8]))
for line in open(expt2):
    if line.startswith('#'): continue
    linesplit = line.split()
    lev = int(float(linesplit[0]))
    if not strat and lev < levtop: continue
    if strat and lev > levtop: continue
    if lev > levbot: continue
    wind_count2.append(int(linesplit[1]))
    wind_fit2.append(float(linesplit[2]))
    temp_count2.append(int(linesplit[3]))
    temp_fit2.append(float(linesplit[4]))
    temp_bias2.append(float(linesplit[5]))
    q_count2.append(int(linesplit[6]))
    q_fit2.append(float(linesplit[7]))
    q_bias2.append(float(linesplit[8]))

fig = plt.figure(figsize=(11,6))
#plt.subplot(1,3,1)
#plt.plot(wind_bias1,levels,color=color1,linewidth=linewidth1,marker='o',label=expt1)
#plt.plot(wind_bias2,levels,color=color2,linewidth=linewidth2,marker='o',label=expt2)
#plt.ylabel('pressure (hPa)')
#plt.title('%s: %s' % (obtypes+' V',region))
#plt.xlabel('BIAS (mps)')
#plt.axis('tight')
#if strat:
#    plt.xlim(-0.1,0.1)
#    plt.ylim(levtop,0)
#else:
#    plt.xlim(-0.1,0.1)
#    plt.ylim(levbot,levtop)
#plt.grid(True)

plt.subplot(1,2,1)
temp_bias1=-np.asarray(temp_bias1)
temp_bias2=-np.asarray(temp_bias2)
q_bias1=-np.asarray(q_bias1)
q_bias2=-np.asarray(q_bias2)
plt.plot(temp_bias1,levels,color=color1,linewidth=linewidth1,marker='o',label=expt1)
plt.plot(temp_bias2,levels,color=color2,linewidth=linewidth2,marker='o',label=expt2)
plt.xlabel('BIAS (K)')
plt.title('%s: %s' % (obtypes+' T',region))
plt.axvline(0)
plt.axis('tight')
if strat:
    plt.xlim(-0.2,0.2)
    plt.ylim(levtop,0)
else:
    plt.xlim(-0.2,0.2)
    plt.ylim(levbot,levtop)
plt.grid(True)

plt.subplot(1,2,2)
plt.plot(q_bias1,levels,color=color1,linewidth=linewidth1,marker='o',label=expt1)
plt.plot(q_bias2,levels,color=color2,linewidth=linewidth2,marker='o',label=expt2)
plt.xlabel('BIAS (g/kg)`')
plt.legend(loc=1)
plt.title('%s: %s' % (obtypes+' RH',region))
plt.axvline(0)
plt.axis('tight')
if strat:
    plt.xlim(-0.2,0.2)
    plt.ylim(levtop,0)
else:
    plt.xlim(-1.0,0.1)
    plt.ylim(levbot,levtop)
plt.grid(True)
plt.figtext(0.5,0.93,'bias F-O (%s)' % dates,horizontalalignment='center',fontsize=18)
if strat:
    plt.savefig('obbias_%s_%s_%s_strat.png' % (expt1,expt2,region))
else:
    plt.savefig('obbias_%s_%s_%s.png' % (expt1,expt2,region))

plt.show()
