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
dates = dateutils.daterange(date1,date2,24)

filename='ocean_geometry_mx025.nc'
ds1 = xr.open_dataset(filename)
geolons = ds1['geolon']
geolats = ds1['geolat']

sstinc = None
for date in dates:
    filename='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/control/INPUT/oras5_increment.nc' % (expt,date)
    print(date)
    ds = xr.open_dataset(filename)
    ds = ds.assign_coords({'xc': geolons,
                           'yc': geolats})
    if sstinc is None:
        sstinc = -ds['pt_inc'][0,...]/len(dates)
    else:
        sstinc -= ds['pt_inc'][0,...]/len(dates)
    ds.close()

fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
print(sstinc)
print(np.asarray(sstinc.min()),np.asarray(sstinc.max))
sstinc.plot(x='xc', y='yc',
              vmin=-1, vmax=1,
              cmap=plt.cm.bwr,
              transform=ccrs.PlateCarree())
plt.title('mean pt_inc (MOM6-ORAS5) at z_l=0.5 %s to %s %s' % (date1,date2,expt))
ax.coastlines()
plt.savefig('mom6inc_%s.png' % expt)
ds1.close()
