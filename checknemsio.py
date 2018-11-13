from ncepnemsio import ncepnemsio_3d
import numpy as np
import sys
filename = sys.argv[1]
nems = ncepnemsio_3d(filename)
lats = nems.lats; lons = nems.lons
print lats.shape, lats.min(), lats.max()
print lons.shape, lons.min(), lons.max()
ug,vg,tempg,zsg,psg,qg,ozg,cwmrg,dpresg,presg = nems.griddata()
print psg.min(), psg.max()
