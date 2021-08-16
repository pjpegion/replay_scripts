import matplotlib
matplotlib.use('Agg')
from netCDF4 import Dataset
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np
import cartopy.crs as ccrs
import dateutils
import sys

date1=sys.argv[1]
date2=sys.argv[2]
expt=sys.argv[3]
dates = dateutils.daterange(date1,date2,6)
nlev = 126

tinc = None
for date in dates:
    filename='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/control/INPUT/fv3_increment6.nc' % (expt,date)
    ds = xr.open_dataset(filename)
    inct = ds['T_inc'][nlev,...]
    incq = ds['sphum_inc'][nlev,...]
    if tinc is None:
        print(inct)
        print(incq)
        tinc = -inct/len(dates)
        qinc = -incq/len(dates)
    else:
        tinc -= inct/len(dates)
        qinc -= incq/len(dates)
    ds.close()

print(np.asarray(tinc.min()), np.asarray(tinc.max()))
print(np.asarray(qinc.min()), np.asarray(qinc.max()))
fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
tinc.plot(x='lon', y='lat',
              vmin=-2., vmax=2.,
              cmap=plt.cm.bwr,
              transform=ccrs.PlateCarree())
plt.title('mean t_inc (FV3-ERA5) at nlev=%s %s to %s %s' % (nlev,date1,date2,expt))
ax.coastlines()
plt.savefig('fv3inct_%s.png' % expt)
fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
qinc.plot(x='lon', y='lat',
              vmin=-0.001, vmax=0.001,
              cmap=plt.cm.bwr,
              transform=ccrs.PlateCarree())
plt.title('mean q_inc (FV3-ERA5) at nlev=%s %s to %s %s' % (nlev,date1,date2,expt))
ax.coastlines()
plt.savefig('fv3incq_%s.png' % expt)
