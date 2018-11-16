#!/contrib/anaconda/2.3.0/bin/python
from netCDF4 import Dataset
import numpy as np
import sys
from vint import vint

filename_fv3 = sys.argv[1]
filename_ifs = sys.argv[2]
filename_inc = sys.argv[3]

ozinc = False # calculate ozone increments

nc = Dataset(filename_fv3)
try:
    # netcdf gaussian grid file output from FV3
    lons_fv3 = nc['grid_xt'][:]
    lats_fv3 = nc['grid_yt'][:]
    nlats_fv3, nlons_fv3 = lons_fv3.shape
    tmp_fv3 = nc['tmp'][:].squeeze()
    spfh_fv3 = nc['spfh'][:].squeeze()
    delp_fv3 = nc['dpres'][:].squeeze()
    u_fv3 = nc['ugrd'][:].squeeze()
    v_fv3 = nc['vgrd'][:].squeeze()
    ps_fv3 = nc['pressfc'][:].squeeze()
    if ozinc:
        o3mr_fv3 = nc['o3mr'][:].squeeze()
    nlevs = v_fv3.shape[0]
    nc.close()
except:
    # nemsio gaussian grid file output by FV3, converted to netcdf
    lons_fv3 = np.radians(nc['lon'][:])
    lats_fv3 = np.radians(nc['lat'][:])
    lons_fv3, lats_fv3 = np.meshgrid(lons_fv3, lats_fv3)
    nlats_fv3, nlons_fv3 = lons_fv3.shape
    tmp_fv3 = (nc['tmpmidlayer'][:].squeeze())
    spfh_fv3 = (nc['spfhmidlayer'][:].squeeze())
    delp_fv3 = (nc['dpresmidlayer'][:].squeeze())
    ps_fv3 = nc['pressfc'][:].squeeze() 
    u_fv3 = (nc['ugrdmidlayer'][:].squeeze())
    v_fv3 = (nc['vgrdmidlayer'][:].squeeze())
    hgtsfc_fv3 = (nc['hgtsfc'][:].squeeze())
    pressfc_fv3 = (nc['pressfc'][:].squeeze())
    if ozinc:
        o3mr_fv3 = (nc['o3mrmidlayer'][:].squeeze())
    nlevs = v_fv3.shape[0]
    nc.close()

nc = Dataset(filename_ifs)
tmp_ifs = nc['tmpmidlayer'][:].squeeze()
spfh_ifs = nc['spfhmidlayer'][:].squeeze()
delp_ifs = nc['dpresmidlayer'][:].squeeze()
ps_ifs = nc['pressfc'][:].squeeze()
u_ifs = nc['ugrdmidlayer'][:].squeeze()
v_ifs = nc['vgrdmidlayer'][:].squeeze()
pressfc_ifs = nc['pressfc'][:].squeeze()
hgtsfc_ifs = nc['hgtsfc'][:].squeeze()
if ozinc:
    o3mr_ifs = nc['o3mrmidlayer'][:].squeeze()
nc.close()
delzs = hgtsfc_ifs - hgtsfc_fv3
print('min/max delzs %s %s' % (delzs.min(), delzs.max()))

# compute increments, write out to netcdf file.
nc = Dataset(filename_inc,'w')
nc.createDimension('lat',nlats_fv3)
nc.createDimension('lon',nlons_fv3)
nc.createDimension('lev',nlevs)
nc.createDimension('ilev',nlevs+1)
lat = nc.createVariable('lat',np.float32,'lat')
lat.units = 'degrees north'
lon = nc.createVariable('lon',np.float32,'lon')
lon.units = 'degrees east'
lev = nc.createVariable('lev',np.float32,'lev')
ilev = nc.createVariable('ilev',np.float32,'ilev')
lat[:] = np.degrees(lats_fv3[::-1,0])
lon[:] = np.degrees(lons_fv3[0,:])
lev[:] = np.arange(nlevs)+1
ilev[:] = np.arange(nlevs+1)+1
u_inc = nc.createVariable('u_inc',np.float32,('lev','lat','lon'))
v_inc = nc.createVariable('v_inc',np.float32,('lev','lat','lon'))
tmp_inc = nc.createVariable('T_inc',np.float32,('lev','lat','lon'))
spfh_inc = nc.createVariable('sphum_inc',np.float32,('lev','lat','lon'))
delp_inc = nc.createVariable('delp_inc',np.float32,('lev','lat','lon'))
if ozinc:
    o3mr_inc = nc.createVariable('o3mr_inc',np.float32,('lev','lat','lon'))
inc = (u_ifs-u_fv3)[::-1,::-1,...]
print 'u increment min/max',inc.min(), inc.max()
u_inc[:] = inc
inc = (v_ifs-v_fv3)[::-1,::-1,...]
print 'v increment min/max',inc.min(), inc.max()
v_inc[:] = inc
inc = (tmp_ifs-tmp_fv3)[::-1,::-1,...]
print 'tmp increment min/max',inc.min(), inc.max()
tmp_inc[:] = inc
inc = (delp_ifs-delp_fv3)[::-1,::-1,...] 
print 'delp increment min/max',inc.min(), inc.max()
delp_inc[:] = inc 
#import matplotlib.pyplot as plt
#clevs = np.linspace(-19,19,20)
##for k in range(nlevs):
##    print k,inc[k].min(), inc[k].max()
#print inc[40].min(),inc[40].max()
#plt.contourf(lons_fv3,lats_fv3,inc[40],clevs,cmap=plt.cm.bwr,extend='both')
#plt.title('delp inc')
#plt.show()
#raise SystemExit
# compute delp_inc from ps_inc
#psinc = ps_ifs-ps_fv3
#print psinc.min(), psinc.max()
#pressi_inc = np.zeros((nlevs+1,nlats_fv3,nlons_fv3),np.float32)
#for k in range(nlevs+1):
#    pressi_inc[k] = bk[k]*psinc
#inc = pressi_inc[1:,::-1,:]-pressi_inc[0:-1,::-1,:]
#import matplotlib.pyplot as plt
#clevs = np.linspace(-19,19,20)
##for k in range(nlevs):
##    print k,inc[k].min(), inc[k].max()
#print inc[40].min(),inc[40].max()
#plt.contourf(lons_fv3,lats_fv3,inc[40],clevs,cmap=plt.cm.bwr,extend='both')
#plt.title('delp inc 2')
#plt.show()
#raise SystemExit
#print 'delp increment min/max',inc.min(), inc.max()
#delp_inc[:] = inc
inc = (spfh_ifs-spfh_fv3)[::-1,::-1,...]
print 'spfh increment min/max',inc.min(), inc.max()
spfh_inc[:] = inc
if ozinc:
    inc = (o3mr_ifs-o3mr_fv3)[::-1,::-1,...]
    print 'o3mr increment min/max',inc.min(), inc.max()
    o3mr_inc[:] = inc
nc.close()
