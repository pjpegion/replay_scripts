import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
import numpy as np
import sys, os
from dateutils import daterange
from netCDF4 import Dataset
expt = sys.argv[1]
date1 = sys.argv[2]
date2 = sys.argv[3]
dates = daterange(date1,date2,6)
datapath = '/scratch2/BMC/gsienkf/whitaker/%s' % expt
lats = None
var = 'T_inc'
#var = 'sphum_inc'
def getmean(data,coslats):
    meancoslats = coslats.mean()
    return (coslats*data).mean()/meancoslats
for date in dates:
    print date
    filename = os.path.join(os.path.join(datapath,date),'control/INPUT/fv3_increment6.nc')
    nc = Dataset(filename)
    inc = nc[var][:].squeeze()[::-1]
    print(inc.min(), inc.max())
    if lats is None:
       lons = nc['lon'][:]
       lats = nc['lat'][:]
       levs = nc['lev'][:]
       nlats = len(lats); nlevs = len(levs)
       print(lats.min(), lats.max())
       lons2,lats2 = np.meshgrid(lons,lats)
       coslats = np.cos(np.radians(lats2))
       rmsinc = inc**2/len(dates)
       meaninc = -inc/len(dates)
    else:
       rmsinc = rmsinc + inc**2/len(dates)
       meaninc = meaninc - inc/len(dates)
    nc.close()
rmsincmap = np.sqrt(rmsinc.copy())
rmsinc = np.sqrt(rmsinc).mean(axis=-1)
meanincmap = meaninc.copy()
meaninc = meaninc.mean(axis=-1)
print rmsinc.min(), rmsinc.max()
print meaninc.min(), meaninc.max()
globalmeaninc=[]
for k in range(nlevs):
    globalmeaninc.append(getmean(meanincmap[k],coslats))
globalmeaninc = np.array(globalmeaninc)
for k in range(nlevs):
    print('%s %6.4f' % (k,globalmeaninc[k]))
levsplot = 100
nlev = 10

if var == 'T_inc':
    clevs = np.arange(0.0,2.0001,0.2)
elif var == 'sphum_inc':
    clevs = np.arange(0.0,1.0001e-3,0.0001)
plt.contourf(lats, levs[0:levsplot], rmsinc[0:levsplot], clevs, cmap=plt.cm.hot_r, extend='both')
plt.title('increment T RMS')
plt.colorbar()
plt.savefig('replay_incrmst.png')

if var == 'T_inc':
    clevs = np.arange(0.0,4.0001,0.2)
elif var == 'sphum_inc':
    clevs = np.arange(0.0,2.0001e-3,0.0002)
plt.figure()
#plt.contourf(lons2, lats2, rmsincmap[nlev], clevs, cmap=plt.cm.hot_r, extend='both')
#plt.title('increment T RMS level %s GFS-16.0.3' % nlev)
#plt.colorbar()

m = Basemap(llcrnrlat=-90,urcrnrlat=90,llcrnrlon=0,urcrnrlon=360,resolution='c')
cs = m.contourf(lons2,lats2,rmsincmap[nlev],clevs,cmap=plt.cm.hot_r,extend='both')
m.drawcoastlines()
m.drawparallels(np.arange(-90,90,30),labels=[1,0,0,0])
m.drawmeridians(np.arange(0,360,60),labels=[0,0,0,1])
m.colorbar()
plt.title('increment T RMS level %s GFS-16.0.3' % nlev)
plt.savefig('replay_incrmst_map.png')

plt.figure()
if var == 'T_inc':
    clevs = np.linspace(-1.0,1.0,21)
elif var == 'sphum_inc':
    clevs = np.linspace(-0.001,0.0001,21)
plt.contourf(lats, levs[0:levsplot], meaninc[0:levsplot], clevs, cmap=plt.cm.bwr, extend='both')
plt.title('increment (GFS-IFS) T mean GFSv16.0.3')
plt.colorbar()
plt.savefig('replay_incmeant.png')

plt.figure()
if var == 'T_inc':
    clevs = np.linspace(-2.5,2.5,21)
elif var == 'sphum_inc':
    clevs = np.linspace(-0.00095,0.00095,21)
#plt.contourf(lons2, lats2, meanincmap[nlev], clevs, cmap=plt.cm.bwr, extend='both')
#plt.title('increment (GFS-IFS) T mean GFSv16.0.3 level %s' % nlev)
#plt.colorbar()
cs = m.contourf(lons2,lats2,meanincmap[nlev],clevs,cmap=plt.cm.bwr,extend='both')
m.drawcoastlines()
m.drawparallels(np.arange(-90,90,30),labels=[1,0,0,0])
m.drawmeridians(np.arange(0,360,60),labels=[0,0,0,1])
m.colorbar()
plt.title('increment (GFS-IFS) T mean GFSv16.0.3 level %s' % nlev)
plt.savefig('replay_incmeant_map.png')

plt.show()
