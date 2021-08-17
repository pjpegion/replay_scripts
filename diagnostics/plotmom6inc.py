import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np
import cartopy.crs as ccrs
import dateutils
import sys

date1=sys.argv[1]
date2=sys.argv[2]
expt=sys.argv[3]
res=sys.argv[4]
dates = dateutils.daterange(date1,date2,24)

filename='ocean_geometry_mx%s.nc' % res
ds1 = xr.open_dataset(filename)
geolons = np.asarray(ds1['geolon'][:])
geolats = np.asarray(ds1['geolat'][:])
ds1.close()

sstinc = None
for date in dates:
    filename='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/control/INPUT/oras5_increment.nc' % (expt,date)
    print(date)
    ds = xr.open_dataset(filename)
    ds = ds.assign_coords({'geolons': (('lath','lonh'),geolons),
                           'geolats': (('lath','lonh'),geolats)})
    if sstinc is None:
        sstinc = -ds['pt_inc'][0,...]/len(dates)
    else:
        sstinc -= ds['pt_inc'][0,...]/len(dates)
    ds.close()

fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
print(sstinc)
print(np.asarray(sstinc.min()),np.asarray(sstinc.max))
sstinc.plot(x='geolons', y='geolats',
              vmin=-1, vmax=1,
              cmap=plt.cm.bwr,
              transform=ccrs.PlateCarree())
plt.title('mean pt_inc (MOM6-ORAS5) at z_l=0.5 %s to %s %s' % (date1,date2,expt))
ax.coastlines()
plt.savefig('mom6inc_%s.png' % expt)
