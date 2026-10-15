from __future__ import print_function
import numpy as np
from netCDF4 import Dataset
import pygrib, sys, time
from interp import regrid
from vint import vint
from dateutils import daterange

date1 = sys.argv[1] # starting analysis date
date2 = sys.argv[2] # ending analysis date
hrinc = 6 # hour increment

# reference fv3 netcdf gaussian grid file to grab orog,level,lat/lon info
filename_fv3 = 'fv3_F384.nc'
# output ifs file (after interpolation to FV3 vertical levels)
# if IFS grid != FV3 grid, error is raised.
# IFS ps reduced to FV3 orography, fields vertically interpolated
# to FV3 levels defined using reduced ifs ps.

# set parameters
rlapse_stdatm = 0.0065
grav = 9.80665; rd = 287.05; cp = 1004.6; rv=461.5

def get_layer_press(pressi,gsi=True):
    kap1 = (rd/cp)+1.0
    kapr = (cp/rd)
    nlevsp1,nlats,nlons = pressi.shape
    nlevs = nlevsp1-1
    press = np.zeros((nlevs,nlats,nlons),np.float32)
    # gsi formula ("phillips vertical interpolation")
    if gsi:
        for k in range(nlevs):
            press[k,...]=((pressi[k,...]**kap1-pressi[k+1,...]**kap1)/\
                         (kap1*(pressi[k,...]-pressi[k+1,...])))**kapr
            #print(k,press[k].min(),press[k].max())
    else:
        press = 0.5*(pressi[1:]+pressi[0:-1])
    return press

def preduce(ps,tpress,t,delzs,rlapse=rlapse_stdatm):
# compute MAPS pressure reduction from model to station elevation
# See Benjamin and Miller (1990, MWR, p. 2100)
# uses 'effective' surface temperature extrapolated
# from virtual temp (tv) at tpress mb
# using specified lapse rate.
# ps - surface pressure to reduce.
# t - virtual temp. at pressure tpress.
# zmodel - model orographic height.
# zob - station height
# delzs = zob-zmodel
# rlapse - lapse rate (positive)
   alpha = rd*rlapse/grav
   # from Benjamin and Miller (http://dx.doi.org/10.1175/1520-0493(1990)118<2099:AASLPR>2.0.CO;2) 
   t0 = t*(ps/tpress)**alpha # eqn 4 from B&M
   #preduce = ps*((t0 + rlapse*(zob-zmodel))/t0)**(1./alpha) # eqn 1 from B&M
   preduce = ps*((t0 + rlapse*delzs)/t0)**(1./alpha) # eqn 1 from B&M
   return preduce

def read_ifs_3d(filename,shortName,nlevs,lons_ifs,lats_ifs,lons_fv3,lats_fv3,flip_lat=True,flip_levs=True):
    grbs_in=pygrib.open(filename)
    grbs = grbs_in.select(shortName=shortName)
    if len(grbs) != nlevs:
        raise ValueError('too many matches in selection')
    ifsdata = np.zeros((nlevs,)+lats_fv3.shape,np.float32)
    for grb in grbs:
        k = grb.level - 1
        if flip_lat:
            ifsdata[k] = regrid(grb.values[::-1,:],lons_ifs[0,:],lats_ifs[:,0],lons_fv3,lats_fv3)
        else:
            ifsdata[k] = regrid(grb.values,lons_ifs[0,:],lats_ifs[:,0],lons_fv3,lats_fv3)
    if flip_levs:
       return ifsdata[::-1]
    else:
       return ifsdata
    grbs_in.close()

# read netcdf FV3 history file, get grid info
nc = Dataset(filename_fv3)
lons_fv3 = nc['grid_xt'][:]
lats_fv3 = nc['grid_yt'][::-1,:] # flip so lats are increasing
nlats_fv3, nlons_fv3 = lons_fv3.shape
ak_fv3 = nc.ak[::-1]; bk_fv3 = nc.bk[::-1]
nlevs_fv3 = len(ak_fv3)-1
#for k in range(nlevs_fv3+1):
#    print('%s %s %s' % (k,ak_fv3[k],bk_fv3[k]))
orog_fv3 = nc['hgtsfc'][:].squeeze()[::-1,:]
nc.close()

ak_ifs = None; lats_ifs = None

for date in daterange(date1,date2,hrinc):
    print('processing data for %s ...' % date)
    # read IFS orography and lnps from grib file.
    # also get lats/lons
    grbs=pygrib.open('ifsanl_2d_F400_%s.grib' % date)  # orog
    grb = grbs.next()
    orog_ifs = grb.values[::-1,:]/grav # flip so lats are increasing
    if lats_ifs is None:
        lats_ifs, lons_ifs = grb.latlons()
        lons_ifs = np.radians(lons_ifs)
        lats_ifs = np.radians(lats_ifs[::-1,:])
        nlats_ifs, nlons_ifs = lons_ifs.shape
    grb = grbs.next()
    ps_ifs = np.exp(grb.values[::-1,:]) # flip so lats are increasing
    grbs.close()
    
    # open 3d file, get ak,bk
    if ak_ifs is None:
        grbs = pygrib.open('ifsanl_3d_F400_%s.grib' % date)
        grb = grbs.next()
        akbk = grb.pv
        nlevsp1_ifs = len(akbk)/2
        # flip levels (from top to bottom to bottom to top)
        ak_ifs = akbk[0:nlevsp1_ifs][::-1]
        bk_ifs = akbk[nlevsp1_ifs:][::-1]
        #for k in range(nlevsp1_ifs):
        #    print('%s %s %s' % (k,ak_ifs[k],bk_ifs[k]))
        grbs.close()
    
    # interpolate 2d IFS fields horizontally to FV3 grid.
    
    orog_ifs = regrid(orog_ifs,lons_ifs[0,:],lats_ifs[:,0],lons_fv3,lats_fv3)
    delzs = orog_ifs - orog_fv3
    print('min/max delzs %s %s' % (delzs.min(), delzs.max()))
    # interpolate transformed ps
    pstmp_ifs = ps_ifs**(rd*rlapse_stdatm/grav) 
    pstmp_ifs = regrid(pstmp_ifs,lons_ifs[0,:],lats_ifs[:,0],lons_fv3,lats_fv3)
    ps_ifs = pstmp_ifs**(grav/(rd*rlapse_stdatm))
    
    nlevs = nlevsp1_ifs-1
    filename = 'ifsanl_3d_F400_%s.grib' % date
    tmp_ifs = read_ifs_3d(filename,'t',nlevs,lons_ifs,lats_ifs,lons_fv3,lats_fv3,flip_levs=True) 
    spfh_ifs = read_ifs_3d(filename,'q',nlevs,lons_ifs,lats_ifs,lons_fv3,lats_fv3,flip_levs=True) 
    u_ifs = read_ifs_3d(filename,'u',nlevs,lons_ifs,lats_ifs,lons_fv3,lats_fv3,flip_levs=True) 
    v_ifs = read_ifs_3d(filename,'v',nlevs,lons_ifs,lats_ifs,lons_fv3,lats_fv3,flip_levs=True) 
    o3mr_ifs = read_ifs_3d(filename,'o3',nlevs,lons_ifs,lats_ifs,lons_fv3,lats_fv3,flip_levs=True) 
    tv_ifs = tmp_ifs + rv*spfh_ifs
    
    # compute pressures for IFS fields on IFS levels (using IFS orog).
    pressi_ifs = np.zeros((nlevs+1,nlats_fv3,nlons_fv3),np.float32)
    for k in range(nlevs+1):
        pressi_ifs[k] = bk_ifs[k]*ps_ifs + ak_ifs[k]
    press_ifs = get_layer_press(pressi_ifs)
    # reduced IFS ps to FV3 orography
    ps_ifs_fv3 =  preduce(ps_ifs,press_ifs[0,:,:],tv_ifs[0,:,:],delzs)
    print('min/max ps before reduction %s %s' % (ps_ifs.min(), ps_ifs.max()))
    print('min/max reduced ps %s %s' % (ps_ifs_fv3.min(), ps_ifs_fv3.max()))
    
    # compute pressures on FV3 levels using ps reduced to FV3 orography
    # (target pressure for vertical interpolation)
    pressi_ifs_fv3 = np.zeros((nlevs_fv3+1,nlats_fv3,nlons_fv3),np.float32)
    for k in range(nlevs_fv3+1):
        pressi_ifs_fv3[k] = bk_fv3[k]*ps_ifs_fv3 + ak_fv3[k]
    press_ifs_fv3 = get_layer_press(pressi_ifs_fv3)
    
    # interpolate IFS fields vertically to FV3 levels linearly in log(p).
    q_ifs = np.zeros((2*nlevs,nlats_fv3,nlons_fv3),np.float32)
    q_ifs[0:nlevs] = spfh_ifs
    q_ifs[nlevs:2*nlevs] = o3mr_ifs
    u_ifs_fv3,v_ifs_fv3,tmp_ifs_fv3,q_ifs_fv3 = \
    vint(2,press_ifs,u_ifs,v_ifs,tmp_ifs,q_ifs,press_ifs_fv3)
    delp_ifs_fv3 = pressi_ifs_fv3[0:-1]-pressi_ifs_fv3[1:]
    #for k in range(nlevs_fv3):
    #    delp_min=delp_ifs_fv3[k].min(); delp_max=delp_ifs_fv3[k].max()
    #    print('%s %s %s' % (k,delp_min,delp_max))
    #pstmp = delp_ifs_fv3.sum(axis=0) + ak_fv3[-1]
    #diff = pstmp-ps_ifs_fv3
    #print(pstmp.min(),pstmp.max())
    #print(diff.min(),diff.max())
    #raise SystemExit
    spfh_ifs_fv3 = q_ifs_fv3[0:nlevs_fv3]
    o3mr_ifs_fv3 = q_ifs_fv3[nlevs_fv3:2*nlevs_fv3]
    
    # write out data.
    
    nc_fv3 = Dataset(filename_fv3,'r')
    filename_out = 'ifsanl_C384_F384_%s.nc' % date
    nc_ifs = Dataset(filename_out,'w',format='NETCDF4_CLASSIC')
    
    # copy global atts
    nc_ifs.setncatts(nc_fv3.__dict__)
    # create dimensions.
    for dimname,dim in nc_fv3.dimensions.items():
        nc_ifs.createDimension(dimname,len(dim))
    # create variables.
    for varname,ncvar in nc_fv3.variables.items():
        if varname in ['ugrd','vgrd','spfh','o3mr','dpres','tmp','hgtsfc','grid_xt','grid_yt',\
                       'pfull','phalf','time','pressfc']:
            if hasattr(ncvar, '_FillValue'):
                FillValue = ncvar._FillValue
            else:
                FillValue = None
            var = nc_ifs.createVariable(varname,ncvar.dtype,ncvar.dimensions,fill_value=FillValue)
            # fill variable attributes.
            attdict = ncvar.__dict__
            if '_FillValue' in attdict:
                del attdict['_FillValue']
            var.setncatts(attdict)
            # flip lats and levels (back to top to bot, north to south)
            if varname == 'ugrd':
                var[0] = u_ifs_fv3[::-1,::-1,...]
            elif varname == 'vgrd':
                var[0] = v_ifs_fv3[::-1,::-1,...]
            elif varname == 'tmp':
                var[0] = tmp_ifs_fv3[::-1,::-1,...]
            elif varname == 'spfh':
                var[0] = spfh_ifs_fv3[::-1,::-1,...]
            elif varname == 'o3mr':
                var[0] = o3mr_ifs_fv3[::-1,::-1,...]
            elif varname == 'dpres':
                var[0] = delp_ifs_fv3[::-1,::-1,...]
            elif varname == 'pressfc':
                var[0] = ps_ifs_fv3[::-1,...]
            elif varname == 'time':
                var[0] = 0.
                var.units = "hours since %s-%s-%s %s:00:00" % (date[0:4],date[5:6],date[6:8],date[8:10])
            else:
                var[:] = ncvar[:]
        else:
            pass
    nc_fv3.close()
    nc_ifs.close()
