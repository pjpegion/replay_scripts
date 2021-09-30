import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np
import cartopy.crs as ccrs
import dateutils
import sys

date=sys.argv[1]
expt1=sys.argv[2]
expt2=sys.argv[3]

filename='ocean_geometry_mx025.nc'
ds1 = xr.open_dataset(filename)
geolons = ds1['geolon']
geolats = ds1['geolat']
datep1 = dateutils.dateshift(date,-2)
yyyy,mm,dd,hh = dateutils.splitdate(datep1)
print(datep1)

sstdiff = None
filename1='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/ocn_%s_%02i_%02i_%02i.nc' % (expt1,date,yyyy,mm,dd,hh)
filename2='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/ocn_%s_%02i_%02i_%02i.nc' % (expt2,date,yyyy,mm,dd,hh)
print(filename1)
print(filename2)
ds1 = xr.open_dataset(filename1)
ds1 = ds1.assign_coords({'xc': geolons,
                         'yc': geolats})
ds2 = xr.open_dataset(filename2)
ds2 = ds2.assign_coords({'xc': geolons,
                         'yc': geolats})
sstdiff = ds1['temp'][0,0,...]-ds2['temp'][0,0,...]
ds1.close(); ds2.close()

fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
print(np.nanmin(np.asarray(sstdiff)),np.nanmax(np.asarray(sstdiff)))
sstdiff.plot(x='xh', y='yh',
              vmin=-1, vmax=1,
              cmap=plt.cm.bwr,
              transform=ccrs.PlateCarree())
plt.title('mean sst pert (control - perturbed replay) at z_l=0.5 %s' % date)
ax.coastlines()
plt.savefig('mom6pert_%s.png' % date)
ds1.close()
