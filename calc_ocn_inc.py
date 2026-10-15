import xarray as xr
import numpy as np
import xesmf as xe
import os
import sys
from scipy import ndimage as nd
def interp_rotated_vector(u_in,v_in,u_out,v_out,ang_in,ang_out):
   # un-stagger currents
   ut = rg_ut(u_in.values)
   vt = rg_vt(v_in.values)
   # rotate currents to earth relative
   urot =   ut*np.cos(ang_in.values) +   vt*np.sin(ang_in.values)
   vrot =   vt*np.cos(ang_in.values) -   ut*np.sin(ang_in.values)
   # interpolate to new grid
   new_urot = rg_tt(urot)
   new_vrot = rg_tt(vrot)
   # rotate currents back to grid relatvie
   new_ut =   new_urot*np.cos(ang_out.values) - new_vrot*np.sin(ang_out.values)
   new_vt =   new_vrot*np.cos(ang_out.values) + new_urot*np.sin(ang_out.values)
   
   # re-stagger currents
   u_out = rg_tu(new_ut)
   v_out = rg_tv(new_vt)
   return u_out,vout

def fill(data, invalid=None):
    """
    Replace the value of invalid 'data' cells (indicated by 'invalid') 
    by the value of the nearest valid data cell

    Input:
        data:    numpy array of any dimension
        invalid: a binary array of same shape as 'data'. True cells set where data
                 value should be replaced.
                 If None (default), use: invalid  = np.isnan(data)

    Output: 
        Return a filled array. 
    """
    #import numpy as np
    #import scipy.ndimage as nd

    if invalid is None: invalid = np.isnan(data)

    ind = nd.distance_transform_edt(invalid, return_distances=False, return_indices=True)
    return data[tuple(ind)]


def adjusthToFitBathymetry(ssh, h,bathy):
    hTolerance = 1.0e-10 #<  Tolerance to exceed adjustment criteria [Z ~> m]
    Angstrom_Z=1.0e-10
    nx=h.shape[2]
    ny=h.shape[1]
    nz=h.shape[0]
    eta=np.zeros([nz+1,ny,nx])
    eta[0,:,:]=ssh
    for k in range(nz):
        eta[k+1,:,:]=eta[k,:,:]-h[k,:,:]
    dz=eta[-1,:,:]+bathy
    for k in range(nz+1):
        eta[k,:,:]=np.where(-eta[k,:,:] > (bathy[:,:] + hTolerance),-bathy,eta[k,:,:])
    for k in range(nz-1,0,-1):
        h[k,:,:]=np.where(eta[k,:,:] < (eta[k+1,:,:] + Angstrom_Z),Angstrom_Z,eta[k,:,:] - eta[k+1,:,:])
    for i in range(nx):
        for j in range(ny):

    #   The whole column is dilated to accommodate deeper topography than
    # the bathymetry would indicate.
            if -eta[nz,j,i] < (bathy[j,i] - hTolerance):
                if eta[0,j,i] <= eta[nz,j,i]:
                    #for k in range(nz):
                    h[:,j,i] = (eta[1,j,i] + bathy[j,i]) / np.float(nz)
                else:
                    dilate = (eta[0,j,i] + bathy[j,i]) / (eta[0,j,i] - eta[nz,j,i])
                    #for k in range(nz):
                    h[:,j,i] = h[:,j,i] * dilate
    return h,eta
# main program   

# specify an output resolution
ires = "mx025"
ores = "mx100"
cdate='2011112303'

# specify a location to use
nemsrc     = "/scratch4/BMC/gsienkf/Philip.Pegion/UFS-coupled/ICS/source/WeightGen/TTout/"
# specifiy output directory
outdir     = "/scratch4/BMC/gsienkf/Philip.Pegion/UFS-coupled/ICS/"+ores+"/"+cdate+"/"
output_file= 'MOM6.mx100.ic.nc'
# ocean model restart location
dirsrc     = "/scratch2/BMC/gsienkf/Lisa.Bengtsson/IC_dir_replay/0.25_ocean_restart/"
# target resolution bathymetry files
bathy_file='/scratch2/BMC/gsienkf/Philip.Pegion/UFS-coupled/1deg_basedir/INPUT/topog.nc'
edits_file='/scratch2/BMC/gsienkf/Philip.Pegion/UFS-coupled/1deg_basedir/INPUT/ufs.topo_edits_011818.nc'

# OPEN ESMF weights file
wgt_dir='/scratch2/BMC/gsienkf/Philip.Pegion/UFS-coupled/ICS/source/WeightGen/TTout/'
grid_file_100=xr.open_dataset(wgt_dir+'tripole.mx100.nc')
grid_file_025=xr.open_dataset(wgt_dir+'tripole.mx025.nc')
wgtsfile_u_to_t = wgt_dir+'tripole.mx025.Cu.to.Ct.bilinear.nc'
wgtsfile_v_to_t = wgt_dir+'tripole.mx025.Cv.to.Ct.bilinear.nc'
wgtsfile_t_to_t1 = wgt_dir+'tripole.mx025.Ct.to.mx100.Ct.bilinear.nc'
wgtsfile_t1_to_u1 = wgt_dir+'tripole.mx100.Ct.to.Cu.bilinear.nc'
wgtsfile_t1_to_v1 = wgt_dir+'tripole.mx100.Ct.to.Cv.bilinear.nc'
wgtsfile_u1_to_t1 = wgt_dir+'tripole.mx025.Cu.to.Ct.bilinear.nc'
wgtsfile_v1_to_t1 = wgt_dir+'tripole.mx025.Cv.to.Ct.bilinear.nc'
wgtsfile_t1_to_t = wgt_dir+'tripole.mx100.Ct.to.mx025.Ct.bilinear.nc'
wgtsfile_t_to_u = wgt_dir+'tripole.mx025.Ct.to.Cu.bilinear.nc'
wgtsfile_t_to_v = wgt_dir+'tripole.mx025.Ct.to.Cv.bilinear.nc'

# OPEN 1/4 degree initial condition files

# rename lat and lons from grid files for ESMF interpolation
mx025_t_grid=grid_file_in.rename({'lonCt': 'lon', 'latCt': 'lat'})
mx025_v_grid=grid_file_in.rename({'lonCv': 'lon', 'latCv': 'lat'})
mx025_u_grid=grid_file_in.rename({'lonCu': 'lon', 'latCu': 'lat'})

mx100_t_grid=grid_file_out.rename({'lonCt': 'lon', 'latCt': 'lat'})
mx100_v_grid=grid_file_out.rename({'lonCv': 'lon', 'latCt': 'lat'})
mx100_u_grid=grid_file_out.rename({'lonCu': 'lon', 'latCu': 'lat'})

# rotation angles for u and v currents
ang_in = grid_file_in.anglet
ang_out= grid_file_out.anglet

# open input data
res0=xr.open_dataset(dirsrc+"MOM.res.nc")
res1=xr.open_dataset(dirsrc+"MOM.res_1.nc")

rg_tt1 = xe.Regridder(mx025_t_grid, mx100_t_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_t_to_t1)
rg_ut = xe.Regridder(mx025_u_grid, mx025_t_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_u_to_t)
rg_vt = xe.Regridder(mx025_v_grid, mx025_t_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_v_to_t)
rg_t1u1 = xe.Regridder(mx100_t_grid, mx100_u_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_t1_to_u1)
rg_t1v1 = xe.Regridder(mx100_t_grid, mx100_v_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_t1_to_v1)

rg_t1t = xe.Regridder(mx025_t_grid, mx100_t_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_t1_to_t)
rg_u1t1 = xe.Regridder(mx025_u_grid, mx025_t_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_u1_to_t1)
rg_v1t1 = xe.Regridder(mx025_v_grid, mx025_t_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_v1_to_t1)
rg_tu = xe.Regridder(mx100_t_grid, mx100_u_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_t_to_u)
rg_tv = xe.Regridder(mx100_t_grid, mx100_v_grid, 'bilinear',periodic=True,reuse_weights=True, filename=wgtsfile_t_to_v)

nx=len(grid_file_out.ni.values)
ny=len(grid_file_out.nj.values)
nz=len(res0.Layer.values)
nz_i=len(res3.Interface.values)

# define land masks
lmask_in = xr.where(grid_file_in['wet'] > 0.0, 1.0, 0.0)
lmask_out = xr.where(grid_file_out['wet'] > 0.0, 1.0, 0.0)
# interpolate mask to new grid
lmask_interp0 = rg_tt(lmask_in.values)
lmask_interp = np.where(lmask_interp0 < 0.99, 0.0, 1.0)

#3d-copies
lmask_interp_3d=np.zeros([nz,ny,nx])
lmask_out_3d = np.zeros([nz,ny,nx])

for i in range(nz):
    lmask_interp_3d[i,:,:]=lmask_interp[:,:]
    lmask_out_3d[i,:,:]=grid_file_out['wet'].values
    
# fill in land points
vars=['Temp','Salt','h','u']
for var in vars:
   for z in range(nz):
      tnew=fill(tmparr)
      res0[var][0,z]=tnew[:,0:-1]

vars=['v']
for var in vars:
   for z in range(nz):
      tnew=fill(tmparr)
      res1[var][0,z]=tnew[:,0:-1]

tnew=fill(tmparr)
res1['ave_ssh'][0]=tnew[:,0:-1]    
# interpolate values to new grid
new_t       = rg_tt(res0['Temp'])
new_s       = rg_tt(res0['Salt'])
new_h       = rg_tt(res0['h'])
new_fra     = rg_tt(res1['frazil'])
new_ssh     = rg_tt(res1['ave_ssh'])

# un-stagger currents
new_u;new_v=interpolate_rotated_vector(res0['u'],res1['v'],ang_in,ang_out)

new_lath=grid_file_out.latCt.mean(axis=1).values
new_lonh=grid_file_out.lonCt.mean(axis=0).values
new_latq=grid_file_out.latCv.mean(axis=1).values
new_lonq=grid_file_out.lonCu.mean(axis=0).values
new_time=res0.Time.values
da_t = xr.DataArray(new_t ,coords=({'lath':(['lath'], new_lath), 'lonh':(['lonh'], new_lonh), 'Layer':(['Layer'], res0['Layer'].values), 'Time':(['Time'], new_time)}), dims=['Time','Layer','lath','lonh']).to_dataset(name='Temp')
da_s = xr.DataArray(new_s ,coords=({'lath':(['lath'], new_lath), 'lonh':(['lonh'], new_lonh), 'Layer':(['Layer'], res0['Layer'].values), 'Time':(['Time'], new_time)}), dims=['Time','Layer','lath','lonh']).to_dataset(name='Salt')
da_h = xr.DataArray(new_h ,coords=({'lath':(['lath'], new_lath), 'lonh':(['lonh'], new_lonh), 'Layer':(['Layer'], res0['Layer'].values), 'Time':(['Time'], new_time)}), dims=['Time','Layer','lath','lonh']).to_dataset(name='h')
da_u = xr.DataArray(new_u,coords=({'lath' : (['lath'], new_lath), 'lonq' : (['lonq'], new_lonq), 'Layer': (['Layer'], res0['Layer'].values), 'Time' : (['Time'], new_time)}), dims=['Time','Layer','lath','lonq']).to_dataset(name='u')
da_v = xr.DataArray(new_v,coords=({'latq' : (['latq'], new_latq), 'lonh' : (['lonh'], new_lonh), 'Layer': (['Layer'], res0['Layer'].values), 'Time' : (['Time'], new_time)}), dims=['Time','Layer','latq','lonh']).to_dataset(name='v')


vars=['Temp','Salt']
for var in vars:
   new_res0[var][:] = np.where(lmask_out_3d == 0.0, 0.0, new_res0[var])

