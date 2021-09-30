import matplotlib
matplotlib.use('Agg')
from netCDF4 import Dataset
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np
import cartopy.crs as ccrs
import dateutils
import sys

date=sys.argv[1]
expt1=sys.argv[2]
expt2=sys.argv[3]
nlev = 126
#nlev = 100

filename1='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/sfg_%s_fhr09_control' % (expt1,date,date)
filename2='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/sfg_%s_fhr09_control' % (expt2,date,date)
print(filename1)
print(filename2)
ds1 = xr.open_dataset(filename1)
ds2 = xr.open_dataset(filename2)
t1 = ds1['tmp'][0,nlev,...]
t2 = ds2['tmp'][0,nlev,...]
ps1 = ds1['pressfc'][0,...]
ps2 = ds2['pressfc'][0,...]
tdiff = t2-t1
psdiff = 0.01*(ps2-ps1)
ds1.close()
ds2.close()

print(np.asarray(tdiff.min()), np.asarray(tdiff.max()))
print(np.asarray(psdiff.min()), np.asarray(psdiff.max()))

fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
tdiff.plot(x='grid_xt', y='grid_yt',
          vmin=-2.5, vmax=2.5,
          cmap=plt.cm.bwr,
          transform=ccrs.PlateCarree())
plt.title('t pert (control-perturbed replay) at nlev=%s %s' % (nlev,date))
ax.coastlines()
plt.savefig('fv3pertt_%s_nlev%s.png' % (date,nlev))

fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
psdiff.plot(x='grid_xt', y='grid_yt',
          vmin=-2., vmax=2.,
          cmap=plt.cm.bwr,
          transform=ccrs.PlateCarree())
plt.title('ps pert (control-perturbed replay) %s' % date)
ax.coastlines()
plt.savefig('fv3pertps_%s.png' % date)
