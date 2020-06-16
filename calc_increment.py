#!/contrib/anaconda/2.3.0/bin/python
##!/contrib/anaconda/anaconda2-4.4.0/bin/python
from __future__ import print_function
from netCDF4 import Dataset
import numpy as np
import sys, time, os
# fortran module for vertical interpolation 
from vintrp import interpolate_vertical as vint

t0 = time.clock()
# read in FV3 background (gaussian grid, netcdf format)
# read in IFS analysis (same gaussian grid, netcdf format)
# reduce IFS ps to FV3 orography, interpolate IFS analyses vertically
# to FV3 levels, compute increments, write out to specified netcdf file
# (compatible with FV3GFS model).

# assume all are on same horizontal grid
filename_fv3 = sys.argv[1]
filename_ifs = sys.argv[2]
filename_inc = sys.argv[3]

# set parameters
rlapse_stdatm = 0.0065
grav = 9.80665; rd = 287.05; cp = 1004.6; rv=461.5
kap1 = (rd/cp)+1.0
kapr = (cp/rd)

def preduce(ps,tpress,tv,delzs,rlapse=rlapse_stdatm):
# compute MAPS pressure reduction from model to station elevation
# See Benjamin and Miller (1990, MWR, p. 2100)
# uses 'effective' surface temperature extrapolated
# from virtual temp (tv) at tpress mb
# using specified lapse rate.
# ps - surface pressure to reduce.
# tv - virtual temp. at pressure tpress.
# zmodel - model orographic height.
# zob - station height
# delzs = zob-zmodel
# rlapse - lapse rate (positive)
   alpha = rd*rlapse/grav
   # from Benjamin and Miller (http://dx.doi.org/10.1175/1520-0493(1990)118<2099:AASLPR>2.0.CO;2) 
   t0 = tv*(ps/tpress)**alpha # eqn 4 from B&M
   preduce = ps*((t0 + rlapse*delzs)/t0)**(1./alpha) # eqn 1 from B&M
   return preduce

ozinc = False # calculate ozone increments
spfhuminc = True # calculate humidity increments
taper_strat = True # taper increments to zero at upper levels

nc = Dataset(filename_fv3)
nc.set_auto_mask(False)

# netcdf gaussian grid file output from FV3
lons_fv3 = nc['grid_xt'][:]
# lats go N to S, flip
# levels go top to bottom, flip
lats_fv3 = nc['grid_yt'][::-1]
nlats_fv3 = len(lats_fv3); nlons_fv3 = len(lons_fv3)
tmp_fv3 = nc['tmp'][:].squeeze()[::-1,::-1,:]
nlevs_fv3 = tmp_fv3.shape[0]
#for k in range(nlevs_fv3):
#    print(k,tmp_fv3[k].min(),tmp_fv3[k].max(),tmp_fv3[k].mean())
spfh_fv3 = nc['spfh'][:].squeeze()[::-1,::-1,:]
delp_fv3 = nc['dpres'][:].squeeze()[::-1,::-1,:]
u_fv3 = nc['ugrd'][:].squeeze()[::-1,::-1,:]
v_fv3 = nc['vgrd'][:].squeeze()[::-1,::-1,:]
ps_fv3 = nc['pressfc'][:].squeeze()[::-1]
orog_fv3 = nc['hgtsfc'][:].squeeze()[::-1]
o3mr_fv3 = nc['o3mr'][:].squeeze()[::-1,::-1,:]
ak_fv3 = nc.ak[::-1]; bk_fv3 = nc.bk[::-1]
nc.close()
# taper increment to zero between these pressure levels
ak_bot = 500.
ak_top = 5.
#print('ak_fv3',ak_fv3.shape,ak_fv3)
#print('bk_fv3',bk_fv3.shape,bk_fv3)
#print('ak_bot,ak_top = ',ak_bot,ak_top)

# taper function for increments.
taper_vert = np.ones(tmp_fv3.shape, np.float32)
if taper_strat:
    for k in range(nlevs_fv3):
        if k < nlevs_fv3/2 and ak_fv3[k] > ak_bot:
            taper_vert[k,...] = 1.
        elif k >= nlevs_fv3/2 and (ak_fv3[k] <= ak_bot and ak_fv3[k] >= ak_top):
            taper_vert[k,...] = (ak_fv3[k] - ak_top)/(ak_bot - ak_top)
            if bk_fv3[k] > 0:
                msg = 'taper below pressure level region not allowed'
                raise ValueError(msg)
        elif k >= nlevs_fv3/2 and ak_fv3[k] < ak_top:
            taper_vert[k,...] = 0.
    #for k in range(nlevs_fv3):
    #    print(k,ak_fv3[k],bk_fv3[k],taper_vert[k,0,0])
    #raise SystemExit

# IFS hybrid levels
# need levels to be bottom to top
nchyb = Dataset(os.path.join(os.path.dirname(filename_ifs),'IFSL137_hyblevs.nc'))
nc.set_auto_mask(False)
ak_ifs = nchyb.ak
bk_ifs = nchyb.bk
if bk_ifs[0] < 1.e-7:
    ak_ifs = nchyb.ak[::-1]; bk_ifs = nchyb.bk[::-1]
#print('ak_ifs',ak_ifs.shape,ak_ifs)
#print('bk_ifs',bk_ifs.shape,bk_ifs)
nchyb.close()
nlevs_ifs = len(ak_ifs)-1

# read IFS, interpolate to FV3 vertical grid
# levels go top to bottom, flip
# lats go N to S, flip
nc = Dataset(filename_ifs)
nc.set_auto_mask(False)
lats_ifs = nc['latitude'][::-1]
# make sure arrays are float32, and stored in fortran memory layout
# to minimize copying in f2py extension vint.
tmp_ifs = np.asfortranarray(nc['t'][:,::-1,::-1,:].squeeze(),dtype=np.float32)
#print(tmp_ifs.shape, tmp_ifs.dtype,tmp_ifs.flags)
#for k in range(nlevs_ifs):
#    print(k,tmp_ifs[k].min(),tmp_ifs[k].max(),tmp_ifs[k].mean())
spfh_ifs = np.asfortranarray(nc['q'][:,::-1,::-1,:].squeeze(),dtype=np.float32)
#print(spfh_ifs.min(), spfh_ifs.max())
tv_ifs = tmp_ifs + rv*spfh_ifs
ps_ifs = np.asfortranarray(np.exp(nc['lnsp'][0,0,::-1,:].squeeze()),dtype=np.float32)
u_ifs = np.asfortranarray(nc['u'][:,::-1,::-1,:].squeeze(),dtype=np.float32)
v_ifs = np.asfortranarray(nc['v'][:,::-1,::-1,:].squeeze(),dtype=np.float32)
orog_ifs = np.asfortranarray(nc['z'][0,0,::-1,:].squeeze()/grav,dtype=np.float32)
#print ('orog_ifs(1,1) = ',orog_ifs[0,0],orog_ifs[-1,-1])
o3mr_ifs = np.asfortranarray(nc['o3'][:,::-1,::-1,:].squeeze(),dtype=np.float32)
#print(o3mr_ifs.min(), o3mr_ifs.max())
nc.close()

# compute pressures for IFS fields on IFS levels (using IFS orog).
pressi_ifs = np.zeros((nlevs_ifs+1,nlats_fv3,nlons_fv3),np.float32)
press_ifs = np.zeros((nlevs_ifs,nlats_fv3,nlons_fv3),np.float32)
for k in range(nlevs_ifs+1):
    pressi_ifs[k] = bk_ifs[k]*ps_ifs + ak_ifs[k]
# level pressures average of interface pressures
#press_ifs = 0.5*(pressi_ifs[1:]+pressi_ifs[0:-1])
# gsi formula ("phillips vertical interpolation")
for k in range(nlevs_ifs):
    press_ifs[k,...]=((pressi_ifs[k,...]**kap1-pressi_ifs[k+1,...]**kap1)/\
                     (kap1*(pressi_ifs[k,...]-pressi_ifs[k+1,...])))**kapr
    #print(k,press_ifs[k].min(),press_ifs[k].max(),press_ifs[k].mean())
# reduced IFS ps to FV3 orography
delzs = orog_ifs - orog_fv3
print('min/max delzs %s %s' % (delzs.min(), delzs.max()))
ps_ifs_fv3 =  preduce(ps_ifs,press_ifs[0,:,:],tv_ifs[0,:,:],delzs)
print('min/max reduced ps %s %s' % (ps_ifs_fv3.min(), ps_ifs_fv3.max()))

psinc = ps_ifs_fv3-ps_fv3
print('ps increment min/max',psinc.min(),psinc.max())
#import matplotlib.pyplot as plt
#print(lats_fv3.min(), lats_fv3.max(),lats_fv3[0],lats_fv3[-1])
#print(lats_ifs.min(), lats_ifs.max(),lats_ifs[0],lats_ifs[-1])
#lons2, lats2 = np.meshgrid(lons_fv3,lats_fv3)
#clevs = np.arange(-10,10.01,1.)
#plt.contourf(lons2,lats2,0.01*psinc,clevs,cmap=plt.cm.bwr,extend='both')
#plt.title('ps inc')

# compute pressures on FV3 levels using ps reduced to FV3 orography
# (target pressure for vertical interpolation)
pressi_ifs_fv3 = np.zeros((nlevs_fv3+1,nlats_fv3,nlons_fv3),np.float32,order='F')
press_ifs_fv3 = np.zeros((nlevs_fv3,nlats_fv3,nlons_fv3),np.float32,order='F')
for k in range(nlevs_fv3+1):
    pressi_ifs_fv3[k] = bk_fv3[k]*ps_ifs_fv3 + ak_fv3[k]
# level pressures average of interface pressures
#press_fv3 = 0.5*(pressi_fv3[1:]+pressi_fv3[0:-1])
# gsi formula ("phillips vertical interpolation")
for k in range(nlevs_fv3):
    press_ifs_fv3[k,...]=((pressi_ifs_fv3[k,...]**kap1-pressi_ifs_fv3[k+1,...]**kap1)/\
                     (kap1*(pressi_ifs_fv3[k,...]-pressi_ifs_fv3[k+1,...])))**kapr
    #print(k,press_ifs_fv3[k].min(),press_ifs_fv3[k].max(),press_ifs_fv3[k].mean())

# interpolate IFS fields vertically to FV3 levels linearly in log(p).
#print(press_ifs.shape, u_ifs.shape, v_ifs.shape, tmp_ifs.shape, spfh_ifs.shape, o3mr_ifs.shape, press_ifs_fv3.shape)
#print(press_ifs.dtype, u_ifs.dtype, v_ifs.dtype, tmp_ifs.dtype, spfh_ifs.dtype, o3mr_ifs.dtype, press_ifs_fv3.dtype)
t1 = time.clock()
u_ifs_fv3,v_ifs_fv3,tmp_ifs_fv3,spfh_ifs_fv3,o3mr_ifs_fv3 = \
vint(press_ifs,u_ifs,v_ifs,tmp_ifs,spfh_ifs,o3mr_ifs,press_ifs_fv3)
#for k in range(nlevs_fv3):
#    print(k,tmp_ifs_fv3[k].min(),tmp_ifs_fv3[k].max(),tmp_ifs_fv3.mean(),tmp_fv3[k].min(),tmp_fv3[k].max(),tmp_fv3.mean())
#for k in range(nlevs_fv3):
#    print(k,spfh_ifs_fv3[k].min(),spfh_ifs_fv3[k].max(),spfh_fv3[k].min(),spfh_fv3[k].max())
#for k in range(nlevs_fv3):
#    print(k,o3mr_ifs_fv3[k].min(),o3mr_ifs_fv3[k].max(),o3mr_fv3[k].min(),o3mr_fv3[k].max())
print('time in vint',time.clock()-t1)
delp_ifs_fv3 = pressi_ifs_fv3[0:-1]-pressi_ifs_fv3[1:]

#plt.figure()
#psinc = (delp_ifs_fv3 - delp_fv3).sum(axis=0)
#print('ps increment min/max',psinc.min(),psinc.max())
#lons2, lats2 = np.meshgrid(lons_fv3,lats_fv3)
#clevs = np.arange(-10,10.01,1.)
#plt.contourf(lons2,lats2,0.01*psinc,clevs,cmap=plt.cm.bwr,extend='both')
#plt.title('ps inc')
#plt.show()

# compute increments, write out to netcdf file.
# NOTE: increments assumed to go S->N, top->bottom
nc = Dataset(filename_inc,'w',format='NETCDF4_CLASSIC')
nc.createDimension('lat',nlats_fv3)
nc.createDimension('lon',nlons_fv3)
nc.createDimension('lev',nlevs_fv3)
nc.createDimension('ilev',nlevs_fv3+1)
lat = nc.createVariable('lat',np.float32,'lat')
lat.units = 'degrees north'
lon = nc.createVariable('lon',np.float32,'lon')
lon.units = 'degrees east'
lev = nc.createVariable('lev',np.float32,'lev')
ilev = nc.createVariable('ilev',np.float32,'ilev')
ak = nc.createVariable('ak',np.float32,'ilev')
bk = nc.createVariable('bk',np.float32,'ilev')
ak[:] = ak_fv3[::-1]
bk[:] = bk_fv3[::-1]
lat[:] = lats_fv3[:]
lon[:] = lons_fv3[:]
lev[:] = np.arange(nlevs_fv3)+1
ilev[:] = np.arange(nlevs_fv3+1)+1
zlib = True # compress 3d vars?
u_inc = nc.createVariable('u_inc',np.float32,('lev','lat','lon'),zlib=zlib)
v_inc = nc.createVariable('v_inc',np.float32,('lev','lat','lon'),zlib=zlib)
tmp_inc = nc.createVariable('T_inc',np.float32,('lev','lat','lon'),zlib=zlib)
spfh_inc = nc.createVariable('sphum_inc',np.float32,('lev','lat','lon'),zlib=zlib)
delp_inc = nc.createVariable('delp_inc',np.float32,('lev','lat','lon'),zlib=zlib)
o3mr_inc = nc.createVariable('o3mr_inc',np.float32,('lev','lat','lon'),zlib=zlib)
inc = (taper_vert*(u_ifs_fv3-u_fv3))[::-1]
print('u increment min/max',inc.min(), inc.max())
u_inc[:] = inc
inc = (taper_vert*(v_ifs_fv3-v_fv3))[::-1]
print('v increment min/max',inc.min(), inc.max())
v_inc[:] = inc
inc = (taper_vert*(tmp_ifs_fv3-tmp_fv3))[::-1]
print('tmp increment min/max',inc.min(), inc.max())
tmp_inc[:] = inc
inc = (taper_vert*(delp_ifs_fv3-delp_fv3))[::-1]
if delp_ifs_fv3.min() < 0 or delp_fv3.min() < 0:
   print('delp_ifs.min(), delp_fv3.min()',delp_ifs_fv3.min(),delp_fv3.min())
   raise ValueError('negative pressure thickness')
print('delp increment min/max',inc.min(), inc.max())
delp_inc[:] = inc 
inc = (taper_vert*(spfh_ifs_fv3-spfh_fv3))[::-1]
print('spfh increment min/max',inc.min(), inc.max())
if not spfhuminc:
    print('zeroing spfh increment')
    spfh_inc[:] = 0
else:
    spfh_inc[:] = inc
inc = (taper_vert*(o3mr_ifs_fv3-o3mr_fv3))[::-1]
print('o3mr increment min/max',inc.min(), inc.max())
if not ozinc:
    print('zeroing o3mr increment')
    o3mr_inc[:] = 0
else:
    o3mr_inc[:] = inc
inc = (taper_vert*(o3mr_ifs_fv3-o3mr_fv3))[::-1]
dt = time.clock()-t0
print('all done, total wallclock time = %s' % dt)
nc.close()
