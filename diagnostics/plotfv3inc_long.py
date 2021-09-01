import matplotlib
matplotlib.use('Agg')
from netCDF4 import Dataset
import matplotlib.pyplot as plt
import xarray as xr
import numpy as np
import cartopy.crs as ccrs
import dateutils
import sys

#datefile=sys.argv[1]
expt=sys.argv[1]
fhr=sys.argv[2]
ifhr=int(fhr)
dates = np.loadtxt('longfcst_dates.txt',dtype=np.int).tolist()
dates = [str(date) for date in dates]
#nlev = 100
nlev=126

tinc = None
for date in dates:
    datev = dateutils.dateshift(date,ifhr)
    filename_fcst='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/longfcst/sfg_%s_fhr%s_control' % (expt,date,date,fhr)
    print(filename_fcst)
    filename_anal='/lustre/f2/dev/Jeffrey.S.Whitaker/era5anl/C384/C384_era5anl_%s.nc' % datev
    print(filename_anal)
    dsf = xr.open_dataset(filename_fcst)
    dsa = xr.open_dataset(filename_anal)
    tf = dsf['tmp'][0,nlev,...]; ta = dsa['tmp'][0,nlev,...]
    qf = dsf['spfh'][0,nlev,...]; qa = dsa['spfh'][0,nlev,...]
    inct = np.asarray(tf)-np.asarray(ta)
    incq = np.asarray(qf)-np.asarray(qa)
    print(inct.min(),inct.max(),incq.min(),incq.max())
    if tinc is None:
        tinc = inct/len(dates)
        qinc = incq/len(dates)
        lats = np.asarray(dsf['lat'][:])
        lons = np.asarray(dsf['lon'][:])
    else:
        tinc += inct/len(dates)
        qinc += incq/len(dates)
    dsf.close(); dsa.close()

print(tinc.min(),tinc.max(),tinc.shape)
print(qinc.min(),qinc.max(),qinc.shape)
fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.coastlines()
ax.set_global()
im = ax.pcolormesh(lons,lats,tinc,
          vmin=-4., vmax=4.,
          cmap=plt.cm.bwr,
          transform=ccrs.PlateCarree())
plt.colorbar(im,shrink=0.9)
plt.title('mean t bias fh=%s (FV3-ERA5) at nlev=%s' % (fhr,nlev))
plt.savefig('fv3inct_nlev%s_%s_fhr%s.png' % (nlev,expt,fhr),bbox_inches='tight')
fig=plt.figure(figsize=(12,5.5))
ax = plt.axes(projection=ccrs.PlateCarree())
ax.set_global()
ax.coastlines()
im = ax.pcolormesh(lons,lats,qinc,
          vmin=-0.002, vmax=0.002,
          cmap=plt.cm.bwr,
          transform=ccrs.PlateCarree())
plt.colorbar(im,shrink=0.9)
plt.title('mean q bias fh=%s (FV3-ERA5) at nlev=%s' % (fhr,nlev))
plt.savefig('fv3incq_nlev%s_%s_fhr%s.png' % (nlev,expt,fhr),bbox_inches='tight')
