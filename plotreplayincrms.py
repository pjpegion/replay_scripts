import matplotlib.pyplot as plt
import numpy as np
import sys, os
from dateutils import daterange
from netCDF4 import Dataset
expt = sys.argv[1]
date1 = sys.argv[2]
date2 = sys.argv[3]
dates = daterange(date1,date2,6)
datapath = '/scratch3/BMC/gsienkf/whitaker/%s' % expt
lats = None
var = 'T_inc'
#var = 'sphum_inc'
for date in dates:
    print date
    filename = os.path.join(os.path.join(datapath,date),'control/INPUT/fv3_increment6.nc')
    nc = Dataset(filename)
    if lats is None:
       lons = nc['lon'][:]
       lats = nc['lat'][:]
       levs = nc['lev'][:]
       nlats = len(lats); nlevs = len(levs)
       rmsinc = (nc[var][:].squeeze())[::-1]**2/len(dates)
       meaninc = (nc[var][:].squeeze())[::-1]/len(dates)
    else:
       rmsinc = rmsinc + (nc[var][:].squeeze())[::-1]**2/len(dates)
       meaninc = meaninc + (nc[var][:].squeeze())[::-1]/len(dates)
    nc.close()
rmsincmap = np.sqrt(rmsinc.copy())
rmsinc = np.sqrt(rmsinc).mean(axis=-1)
meanincmap = meaninc.copy()
meaninc = meaninc.mean(axis=-1)
print rmsinc.min(), rmsinc.max()
print meaninc.min(), meaninc.max()
nlev = 15

if var == 'T_inc':
    clevs = np.arange(0.0,2.0001,0.2)
elif var == 'sphum_inc':
    clevs = np.arange(0.0,1.0001e-3,0.0001)
plt.contourf(lats, levs, rmsinc, clevs, cmap=plt.cm.hot_r, extend='both')
plt.title('increment T RMS')
plt.colorbar()
plt.savefig('replay_incrmst.png')

if var == 'T_inc':
    clevs = np.arange(0.0,4.0001,0.2)
elif var == 'sphum_inc':
    clevs = np.arange(0.0,2.0001e-3,0.0002)
plt.figure()
lons2,lats2 = np.meshgrid(lons,lats)
plt.contourf(lons2, lats2, rmsincmap[nlev], clevs, cmap=plt.cm.hot_r, extend='both')
plt.title('increment T RMS level %s' % nlev)
plt.colorbar()
plt.savefig('replay_incrmst_map.png')

plt.figure()
if var == 'T_inc':
    clevs = np.linspace(-0.95,0.95,20)
elif var == 'sphum_inc':
    clevs = np.linspace(-0.00045,0.00045,20)
plt.contourf(lats, levs, meaninc, clevs, cmap=plt.cm.bwr, extend='both')
plt.title('increment T mean')
plt.colorbar()
plt.savefig('replay_incmeant.png')

plt.figure()
if var == 'T_inc':
    clevs = np.linspace(-1.95,1.95,20)
elif var == 'sphum_inc':
    clevs = np.linspace(-0.00095,0.00095,20)
plt.contourf(lons2, lats2, meanincmap[nlev], clevs, cmap=plt.cm.bwr, extend='both')
plt.title('increment T mean level %s' % nlev)
plt.colorbar()
plt.savefig('replay_incmeant_map.png')

plt.show()

