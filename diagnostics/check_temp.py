import dateutils
from netCDF4 import Dataset
import sys
date1 = sys.argv[1]
date2 = sys.argv[2]
dates = dateutils.daterange(date1,date2,6)
datamin=200; datamax=350
for date in dates:
    for ntile in range(1,7):
        tile = 'tile%s' % ntile
        nc=Dataset('../../C384_replay_p8/%s/control/INPUT/fv_core.res.%s.nc' % (date,tile))
        data=nc['T'][0,-1,...]
        if data.min() < datamin or data.max() > datamax: 
            print('warning: unphysical temp for %s (%s)' % (date,tile))
            print(data.min(), data.max())
