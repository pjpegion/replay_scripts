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

tinc = None
for date in dates:
    filename='/lustre/f2/scratch/Jeffrey.S.Whitaker/%s/%s/control/INPUT/fv3_increment6.nc' % (expt,date)
    ds = xr.open_dataset(filename)
    inct = ds['T_inc'][::-1,...].mean(axis=-1)
    incq = ds['sphum_inc'][::-1,...].mean(axis=-1)
    print(date)
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

fig=plt.figure(figsize=(10,8))
clevs = np.linspace(-1.5,1.5,21)
levsplot=100
plt.contourf(tinc.lat, np.arange(levsplot), tinc[0:levsplot], clevs, cmap=plt.cm.bwr, extend='both')
plt.colorbar()
plt.title('t_inc (FV3-ERA5) %s-%s %s' % (date1,date2,expt))
plt.savefig('fv3inct_zm_%s.png' % expt)

fig=plt.figure(figsize=(10,8))
clevs = np.linspace(-0.0008,0.0008,21)
plt.contourf(qinc.lat, np.arange(levsplot), qinc[0:levsplot], clevs, cmap=plt.cm.bwr, extend='both')
plt.colorbar()
plt.title('q_inc (FV3-ERA5) %s-%s %s' % (date1,date2,expt))
plt.savefig('fv3incq_zm_%s.png' % expt)
