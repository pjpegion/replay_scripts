module interpolation_mod
    implicit none
contains
! bilinear interpolation of 2d fields
subroutine interp_2d(src_data,dst_data,S,col,row,n_s,nx,ny,nxa,nya)


real(kind=8), intent(in)    :: src_data(:,:),S(:)
real(kind=8), intent(inout) :: dst_data(:,:)
integer,      intent(in)    :: col(:),row(:),n_s,nx,ny,nxa,nya
! locals
real(kind=8), allocatable :: src_tmp(:)
real(kind=8), allocatable :: dst_tmp(:)
integer :: i,s_idx,d_idx


allocate(src_tmp(nx*ny))
allocate(dst_tmp(nxa*nya))

src_tmp=reshape(src_data,[nx*ny])
dst_tmp = 0.0d0  ! Initialize destination grid
do i = 1, n_s
    s_idx = col(i)
    d_idx = row(i)
    dst_tmp(d_idx) = dst_tmp(d_idx) + (S(i) * src_tmp(s_idx))
end do
dst_data=reshape(dst_tmp,[nxa,nya])
deallocate(src_tmp,dst_tmp)
end subroutine interp_2d

! bilinear interplation for 3d fields
subroutine interp_3d(src_data,dst_data,S,col,row,n_s,nx,ny,nz,nxa,nya)
implicit none
real(kind=8), intent(in)    :: src_data(:,:,:),S(:)
real(kind=8), intent(inout) :: dst_data(:,:,:)
integer,      intent(in)    :: col(:),row(:),n_s,nx,ny,nz,nxa,nya
! locals
real(kind=8), allocatable :: src_tmp(:,:)
real(kind=8), allocatable :: dst_tmp(:,:)
integer :: i,s_idx,d_idx

allocate(src_tmp(nx*ny,nz))
allocate(dst_tmp(nxa*nya,nz))
!print*,'allocating',nx,ny,nz
!print*,'src data',size(src_data(:,1,1)),size(src_data(1,:,1)),size(src_data(1,1,:))
!print*,'src tmp',size(src_tmp)
src_tmp=reshape(src_data,[nx*ny,nz])
dst_tmp = 0.0d0  ! Initialize destination grid
do i = 1, n_s
    s_idx = col(i)
    d_idx = row(i)
    dst_tmp(d_idx,:) = dst_tmp(d_idx,:) + (S(i) * src_tmp(s_idx,:))
end do
dst_data=reshape(dst_tmp,[nxa,nya,nz])
deallocate(src_tmp,dst_tmp)
end subroutine interp_3d

! verical interpolation
subroutine interp_vertical( tData, sData, xLoc, yLoc,nx,ny,nz )
! Inputs: xData = a vector of the x-values of the data to be interpolated
!         xLoc  = a vector of the x-values where interpolation should be
!         yLoc  = a vector of the x-values where interpolation should be
!         performed
! Output: yData = a vector of the resulting interpolated values

  implicit none

  real*8, intent(inout) :: tData(nx,ny,nz)
  real*8, intent(inout) :: sData(nx,ny,nz)
  real*8, intent(in) :: xLoc(nx,ny,nz),yLoc(nx,ny,nz)
  integer, intent(in) :: nx,ny,nz
  integer :: inputIndex, dataIndex,z,z2,i,j,i1,j1
  real :: weight
  real :: t_tmp(nz),s_tmp(nz),u_tmp(nz),v_tmp(nz)
  logical :: lprint

  i1=121
  j1=149
  lprint=.false.
  do j=1,ny
     do i=1,nx
        !lprint=.false.
        !if (i.EQ.i1.AND.j.EQ.j1) lprint=.true.

        t_tmp(:)=tData(i,j,:)
        s_tmp(:)=sData(i,j,:)
        do z = 1, nz
           if (yLoc(i,j,z) > xLoc(i,j,1)) then !extrapolate increment to surface
              tData(i,j,z) = t_tmp(1)
              sData(i,j,z) = s_tmp(1)
              !if (lprint) print*,'top     ',z,yLoc(i,j,z),xLoc(i,j,1),s_tmp(1)
           else if (yLoc(i,j,z) < xLoc(i,j,nz)) then !extrapolate increment to surface
              tData(i,j,z) = t_tmp(nz)
              sData(i,j,z) = s_tmp(nz)
              !if (lprint) print*,'bottom  ',z,yLoc(i,j,z),xLoc(i,j,nz),s_tmp(nz)
           else ! find layer just above taget layer
              do z2 = 1, nz
                 if (yLoc(i,j,z) < xLoc(i,j,z2)) cycle
                 weight = (yLoc(i,j,z) - xLoc(i,j,z2))/(xLoc(i,j,z2-1)-xLoc(i,j,z2))
                 tData(i,j,z) = (1.0-weight)*t_tmp(z2) + weight*t_tmp(z2-1)
                 sData(i,j,z) = (1.0-weight)*s_tmp(z2) + weight*s_tmp(z2-1)
              !   if (lprint) print*,'interp ',z,yLoc(i,j,z),xLoc(i,j,z2),weight,z2,tData(i,j,z),t_tmp(z2-1),t_tmp(z2)
                 exit
              end do
           endif
        end do
     end do
  end do
end subroutine

subroutine expand_mask(mask,width,nx,ny)

   real(kind=8),intent(inout) :: mask(:,:)
   integer, intent(in) :: width,nx,ny
   real(kind=8),allocatable :: new_mask(:,:)
   integer :: i,j

   allocate(new_mask(nx,ny))
 
   new_mask = mask ! Start with original
   do j = 1+width, ny-width
       do i = 1+width,nx-width
           if (minval(mask(i-width:i+width, j-width:j+width)) == 0) then
               new_mask(i,j) = 0
           end if
       end do
   end do

   mask=new_mask
   deallocate(new_mask)

end subroutine

end module interpolation_mod

program  calc_oras5_incrment
use netcdf
use interpolation_mod

implicit none
integer                 :: ncid_fg,ncid_fg1,ncid_anl,ncid_inc,varid,dimid
integer                 :: xt_dim_id,yt_dim_id,xt_var_id,yt_var_id
integer                 :: xq_dim_id,yq_dim_id,xq_var_id,yq_var_id
integer                 :: varid1,varid2,varid3,width
integer                 :: zl_dim_id,zl_var_id,ierr,fid

include 'netcdf.inc'

integer     :: i,j,k,nx,ny,nz,nxa,nya,nz2,cct,nargs,iforcing_factor
integer     :: i1,i2,j1,j2,nvars,i0,j0
character*80 :: fname_fg,fname_fg1,fname_anl,fname_inc
character*240 :: path_fg,path_anl

real(kind=8),allocatable,dimension(:,:,:)   :: src_2d
real(kind=8),allocatable,dimension(:,:,:,:) :: src_3d
real(kind=8),allocatable,dimension(:)       :: z_fg
real(kind=8),allocatable,dimension(:,:)     :: ssh_anl,areaS
real(kind=8),allocatable,dimension(:,:,:)   :: pt_anl ,pt_inc,h_anl
real(kind=8),allocatable,dimension(:,:,:)   :: s_anl ,s_inc,area
real(kind=8),allocatable,dimension(:,:)     :: ssh_fg , mask_anl, mask_fg, mask_fgi, mask
real(kind=8),allocatable,dimension(:,:,:)   :: pt_fg,h_fg,s_fg,depth_fg,depth_fgi,depth_anli,depth_anl
real(kind=8),allocatable,dimension(:,:,:)   :: pt_fgi,s_fgi
real(kind=8),allocatable,dimension(:,:,:)   :: pt_inc_out,s_inc_out

real(kind=8),allocatable,dimension(:) :: lath,lonh
real(kind=8) :: inv_sumwt2d,inv_sumwt,undef
character(len=nf90_max_name) :: varname
character*10 :: analdate
character*240 :: expt,oras5path,wgt_dir
character*4 :: yyyy
character*2 :: mm,dd,hh
character*3 charnin

real forcing_factor
! Dimensions and Handles
integer :: n_s1,n_s2, ncid
integer, allocatable :: col1(:),col2(:),row1(:),row2(:)
double precision, allocatable :: S1(:),S2(:)

integer :: s_idx, d_idx

print*,'starting'
i0=481
j0=504
i1=121
j1=149

undef=-1.e+34
cct=1

! target grid is GLORe which i 1-deg
nxa=360
nya=320

nargs=iargc()
print*,'get args'
if (nargs.EQ.3) then
   call getarg(1,analdate)
   call getarg(2,expt)
   call getarg(3,oras5path)
   forcing_factor=1.0
else if (nargs.EQ.4) then
   call getarg(1,analdate)
   print*,'analdate=',analdate
   call getarg(2,expt)
   print*,'expt=',expt
   call getarg(3,oras5path)
   print*,'oras5path=',oras5path
   call getarg(4,charnin)
   print*,'charnin=',charnin
   read(charnin,'(i3)') iforcing_factor ! percent
   forcing_factor=iforcing_factor/100.
else
   print*,'usage calc_increment <date> <expt path> <oras5 path> <iau_forcing_factor>'
   STOP
endif

! Open NetCDF and get dimension for background to analysis grid
wgt_dir='/scratch4/BMC/gsienkf/Philip.Pegion/replay_data/input/regridding_weights/'
print*,'opening',trim(wgt_dir)//"tripole.mx025.Ct.to.mx100.Ct.bilinear.nc"
call check(nf90_open(trim(wgt_dir)//"tripole.mx025.Ct.to.mx100.Ct.bilinear.nc", NF90_NOWRITE, ncid),cct)
call check(nf90_inq_dimid(ncid, "n_s", varid),cct)
call check(nf90_inquire_dimension(ncid, varid, len = n_s1),cct)

! Allocate and Read weights
allocate(S1(n_s1), col1(n_s1), row1(n_s1))
    
call check(nf90_inq_varid(ncid, "S", varid),cct)
call check(nf90_get_var(ncid, varid, S1),cct)
call check(nf90_inq_varid(ncid, "col", varid),cct)
call check(nf90_get_var(ncid, varid, col1),cct)
call check(nf90_inq_varid(ncid, "row", varid),cct)
call check(nf90_get_var(ncid, varid, row1),cct)
call check(nf90_close(ncid),cct)

! Open NetCDF and get dimension for analysis to background grid
wgt_dir='/scratch4/BMC/gsienkf/Philip.Pegion/replay_data/input/regridding_weights/'
print*,'opening',trim(wgt_dir)//"tripole.mx100.Ct.to.mx025.Ct.bilinear.nc"
call check(nf90_open(trim(wgt_dir)//"tripole.mx100.Ct.to.mx025.Ct.bilinear.nc", NF90_NOWRITE, ncid),cct)
call check(nf90_inq_dimid(ncid, "n_s", varid),cct)
call check(nf90_inquire_dimension(ncid, varid, len = n_s2),cct)

! 2. Allocate and Read weights
allocate(S2(n_s2), col2(n_s2), row2(n_s2))
    
call check(nf90_inq_varid(ncid, "S", varid),cct)
call check(nf90_get_var(ncid, varid, S2),cct)
call check(nf90_inq_varid(ncid, "col", varid),cct)
call check(nf90_get_var(ncid, varid, col2),cct)
call check(nf90_inq_varid(ncid, "row", varid),cct)
call check(nf90_get_var(ncid, varid, row2),cct)
call check(nf90_close(ncid),cct)



yyyy=analdate(1:4)
mm=analdate(5:6)
dd=analdate(7:8)
hh=analdate(9:10)

! open up MOM6 bg file to get grid info
path_fg=trim(expt)//'/'
fname_fg=yyyy//mm//dd//'.'//hh//'0000.MOM.res.nc'
fname_fg1=yyyy//mm//dd//'.'//hh//'0000.MOM.res_1.nc'
path_anl=trim(oras5path)//'/'
fname_anl='ocn_analysis.'//yyyy//mm//dd//'12.nc'
fname_inc='mom6_increment.nc'

fid=33
open (fid,file=trim(path_fg)//'logs/calc_ocn_inc.out')
print*,'iau_forcing_factor=',forcing_factor
print*,'opening ocean_hgrid.nc'
call check(NF90_OPEN('/scratch4/BMC/gsienkf/Philip.Pegion/UFS-datm/mx100/basedir/INPUT/ocean_hgrid.nc',NF90_NOWRITE,ncid_fg),cct)
call check(NF90_INQ_DIMID(ncid_fg,'nx',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nx),cct)
call check(NF90_INQ_DIMID(ncid_fg,'ny',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=ny),cct)
allocate(areaS(nx,ny))
call check(NF90_INQ_VARID(ncid_fg,'area',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,areaS(:,:)),cct)
call check(nf90_close(ncid_fg),cct)

! open land masks
print*,'opening ocean_mask_mx025.nc'
call check(NF90_OPEN('/scratch4/BMC/gsienkf/Philip.Pegion/UFS-datm/mx025/basedir/INPUT/ocean_mask.nc',NF90_NOWRITE,ncid_fg),cct)
call check(NF90_INQ_DIMID(ncid_fg,'nx',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nx),cct)
call check(NF90_INQ_DIMID(ncid_fg,'ny',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=ny),cct)
allocate(mask_fg(nx,ny))
allocate(mask(nxa,nya))
allocate(mask_fgi(nxa,nya))
call check(NF90_INQ_VARID(ncid_fg,'mask',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,mask_fg(:,:)),cct)
call check(nf90_close(ncid_fg),cct)
width=4
!open(30,file='mask.bin',form='unformatted')
!write(30) real(mask_fg,kind=4)
call expand_mask(mask_fg,width,nx,ny)
!write(30) real(mask_fg,kind=4)
!close(30)

call check(NF90_OPEN('/scratch4/BMC/gsienkf/Philip.Pegion/UFS-datm/mx100/basedir/INPUT/ocean_mask.nc',NF90_NOWRITE,ncid_fg),cct)
call check(NF90_INQ_DIMID(ncid_fg,'nx',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nx),cct)
call check(NF90_INQ_DIMID(ncid_fg,'ny',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=ny),cct)
call check(NF90_INQ_VARID(ncid_fg,'mask',varid),cct)
allocate(mask_anl(nxa,nya))
print*,'reading in mask_anl',size(mask_anl(:,1)),size(mask_anl(1,:)),nx,ny
call check(NF90_GET_VAR(ncid_fg,varid,mask_anl(:,:)),cct)
call check(nf90_close(ncid_fg),cct)

print*,'opening ',trim(path_fg)//trim(fname_fg)
call check(NF90_OPEN(trim(path_fg)//trim(fname_fg),NF90_NOWRITE,ncid_fg),cct)
print*,'opening ',trim(path_fg)//trim(fname_fg1)
call check(NF90_OPEN(trim(path_fg)//trim(fname_fg1),NF90_NOWRITE,ncid_fg1),cct)
! get dimensions
!lonh
call check(NF90_INQ_DIMID(ncid_fg,'lonh',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nx),cct)
allocate(lonh(nx))
call check(NF90_GET_VAR(ncid_fg,dimid,lonh),cct)

!lath
call check(NF90_INQ_DIMID(ncid_fg,'lath',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=ny),cct)
allocate(lath(ny))
call check(NF90_GET_VAR(ncid_fg,dimid,lath),cct)

call check(NF90_INQ_DIMID(ncid_fg,'Layer',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nz),cct)
! allocate arrays

!! interpolat to 1-deg


! 1deg arrays
allocate(pt_fgi(nxa,nya,nz))
allocate(pt_anl(nxa,nya,nz))
allocate(pt_inc(nxa,nya,nz))
allocate(s_fgi(nxa,nya,nz))
allocate(s_anl(nxa,nya,nz))
allocate(s_inc(nxa,nya,nz))
allocate(h_anl(nxa,nya,nz))
allocate(ssh_fg(nxa,nya))
allocate(ssh_anl(nxa,nya))
allocate(depth_fgi(nxa,nya,nz))
allocate(depth_anl(nxa,nya,nz))
allocate(area(nxa,nya,nz))

allocate(z_fg(nz))

! 0.25 degree arrays
allocate(src_2d(nx,ny,1))
allocate(src_3d(nx,ny,nz,1))
allocate(depth_anli(nx,ny,nz))
allocate(depth_fg(nx,ny,nz))
allocate(pt_fg(nx,ny,nz))
allocate(s_fg(nx,ny,nz))
allocate(h_fg(nx,ny,nz))
allocate(pt_inc_out(nx,ny,nz))
allocate(s_inc_out(nx,ny,nz))

!get Layer values
call check(NF90_INQ_VARID(ncid_fg,'Layer',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,z_fg(:)),cct)
! get F.G. fields
!call check(nf90_inquire(ncid, nVariables = nvars),cct)
!do i = 1, nvars
!     call check(nf90_inquire_variable(ncid, i, name = varname),cct)
!     print *, "Variable ", i, ": ", trim(varname)
!end do

! interpolate to analysis grid
call interp_2d(mask_fg,mask_fgi,S1,col1,row1,n_s1,nx,ny,nxa,nya)

! SSH
call check(NF90_INQ_VARID(ncid_fg1,'ave_ssh',varid),cct)
call check(NF90_GET_VAR(ncid_fg1,varid,src_2d),cct)
ssh_fg=src_2d(:,:,1)

! Temp
call check(NF90_INQ_VARID(ncid_fg,'Temp',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,src_3d),cct)
pt_fg=src_3d(:,:,:,1)

! Salinity
call check(NF90_INQ_VARID(ncid_fg,'Salt',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,src_3d),cct)
s_fg=src_3d(:,:,:,1)

! thickness
call check(NF90_INQ_VARID(ncid_fg,'h',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,src_3d),cct)
h_fg=src_3d(:,:,:,1)

print *, "horizontal Interpolation complete."


!deallocate(S, col, row)
call check(nf90_close(ncid_fg),cct)
call check(nf90_close(ncid_fg1),cct)

! define incrment files
!print*,'creating',trim(fname_inc)
!call check(NF90_CREATE(trim(fname_inc),cmode=NF90_CLOBBER,ncid=ncid_inc),cct)
call check(NF90_CREATE(trim(fname_inc),cmode=or(nf90_clobber,nf90_64bit_offset),ncid=ncid_inc),cct)
call check(NF90_DEF_DIM(ncid_inc,"lonh",nx,xt_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"lath",ny,yt_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"Layer",nz,zl_dim_id),cct)
  !> - Define the dimension variables.
call check(NF90_DEF_VAR(ncid_inc,"lonh",NF90_DOUBLE,(/ xt_dim_id /), xt_var_id),cct)
call check(NF90_PUT_ATT(ncid_inc,xt_var_id,"long_name","Longitude"),cct)
call check(NF90_PUT_ATT(ncid_inc,xt_var_id,"cartesian_axis","X"),cct)
call check(NF90_PUT_ATT(ncid_inc,xt_var_id,"units","degrees_E"),cct)
call check(NF90_DEF_VAR(ncid_inc,"lath",NF90_DOUBLE,(/ yt_dim_id /), yt_var_id),cct)
call check(NF90_PUT_ATT(ncid_inc,yt_var_id,"long_name","Latitude"),cct)
call check(NF90_PUT_ATT(ncid_inc,yt_var_id,"cartesian_axis","Y"),cct)
call check(NF90_PUT_ATT(ncid_inc,yt_var_id,"units","degrees_N"),cct)
call check(NF90_DEF_VAR(ncid_inc,"Layer",NF90_DOUBLE,(/ zl_dim_id /), zl_var_id),cct)
call check(NF90_PUT_ATT(ncid_inc,zl_var_id,"long_name","Depth at cell center"),cct)
call check(NF90_PUT_ATT(ncid_inc,zl_var_id,"cartesian_axis","Z"),cct)
call check(NF90_PUT_ATT(ncid_inc,zl_var_id,"units","meter"),cct)
call check(NF90_PUT_ATT(ncid_inc,zl_var_id,"positive","down"),cct)


call check(NF90_DEF_VAR(ncid_inc,"pt_inc",NF90_DOUBLE,(/xt_dim_id, yt_dim_id ,zl_dim_id/), varid1),cct)
call check(NF90_PUT_ATT(ncid_inc,varid1,"long_name","ORAS5 Potential Temperature increments"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid1,"units","degC"),cct)
call check(NF90_DEF_VAR(ncid_inc,"s_inc",NF90_DOUBLE,(/xt_dim_id, yt_dim_id ,zl_dim_id/), varid2),cct)
call check(NF90_PUT_ATT(ncid_inc,varid2,"long_name","ORAS5 Salinity increments"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid2,"units","PPT"),cct)
call check(NF90_DEF_VAR(ncid_inc,"h_fg",NF90_DOUBLE,(/xt_dim_id, yt_dim_id ,zl_dim_id/), varid3),cct)
call check(NF90_PUT_ATT(ncid_inc,varid3,"long_name","Background thickness"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid3,"units","m"),cct)
call check(NF90_ENDDEF(ncid_inc),cct)


! read in analysis (GLOR-E)
print*,'opening ',trim(path_anl)//trim(fname_anl)
call check(NF90_OPEN(trim(path_anl)//trim(fname_anl),NF90_NOWRITE,ncid_anl),cct)
! get dimensions
call check(NF90_INQ_DIMID(ncid_anl,'lonh',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_anl,dimid,len=nxa),cct)
call check(NF90_INQ_DIMID(ncid_anl,'lath',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_anl,dimid,len=nya),cct)
call check(NF90_INQ_DIMID(ncid_anl,'Layer',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_anl,dimid,len=nz),cct)
ierr=0
if (ierr.NE.0) STOP

! get analysis fields
call check(NF90_INQ_VARID(ncid_anl,'ave_ssh',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,ssh_anl(:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'Temp',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,pt_anl(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'Salt',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,s_anl(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'h',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,h_anl(:,:,:)),cct)
call check(NF90_CLOSE(ncid_anl),cct)
print*,'closed',cct

! write grid info to netcdf file

call check(NF90_PUT_VAR(ncid_inc,xt_var_id,lonh),cct)
call check(NF90_PUT_VAR(ncid_inc,yt_var_id,lath),cct)
call check(NF90_PUT_VAR(ncid_inc,zl_var_id,z_fg),cct)

! interpolate analysis to background vertical levels
! interpolate to first guess depth
depth_anl(:,:,1)=ssh_anl(:,:)-0.5*h_anl(:,:,1)
depth_fg(:,:,1)=ssh_fg(:,:)-0.5*h_fg(:,:,1)
print*,'depth_fg=',depth_fg(i0,j0,1),ssh_fg(i0,j0),h_fg(i0,j0,1)
print*,'depth_anl=',depth_anl(i1,j1,1),ssh_anl(i1,j1),h_anl(i1,j1,1)
do k=2,nz
   depth_anl(:,:,k)=ssh_anl(:,:)-(0.5*h_anl(:,:,k)+SUM(h_anl(:,:,1:k-1),3))
   depth_fg(:,:,k)=ssh_fg(:,:)-(0.5*h_fg(:,:,k)+SUM(h_fg(:,:,1:k-1),3))
enddo
! interpolate background depths to analysis grid
call interp_3d(depth_fg, depth_fgi,S1,col1,row1,n_s1,nx,ny,nz,nxa,nya)
print*,'depth_fgi=',depth_anli(i1,j1,1)
! vertical interpolation of background to analysis depths
call interp_vertical( pt_anl,s_anl,depth_anl,depth_fgi,nxa,nya,nz)
call interp_3d(pt_fg, pt_fgi,S1,col1,row1,n_s1,nx,ny,nz,nxa,nya)
call interp_3d(s_fg , s_fgi, S1,col1,row1,n_s1,nx,ny,nz,nxa,nya)

! compute incrments
pt_inc(:,:,:)=forcing_factor*(pt_anl(:,:,:) - pt_fgi(:,:,:))
s_inc(:,:,:)=forcing_factor*(s_anl(:,:,:) - s_fgi(:,:,:))

!aggregate area to A-grid
DO j=1,nya
   j1=(j-1)*2+1
   j2=j1+1
   DO i=1,nxa
      i1=(i-1)*2+1
      i2=i1+1
      area(i,j,:)=areaS(i1,j1)+areaS(i1,j2)+areaS(i2,j1)+areaS(i2,j2)
   ENDDO
ENDDO
deallocate(areaS)


! mask out missing values
mask=0.0
WHERE(mask_anl .GT. 0.999 .AND. mask_fgi .GT. 0.999 )
   mask=1.0
ENDWHERE

! debug checks
!open(22,file='depths_mx100.bin',form='unformatted')
!do i=1,nz
!   write(22) real(depth_anl(:,:,i),kind=4)
!enddo
!write(22) real(mask_anl,kind=4)
!write(22) real(mask_fgi,kind=4)
!write(22) real(mask,kind=4)
!close(22)
!open(23,file='depths_mx025.bin',form='unformatted')
!do i=1,nz
!write(23) real(depth_anli(:,:,i),kind=4)
!enddo
!do i=1,nz
!write(23) real(depth_fg(:,:,i),kind=4)
!enddo
!write(23) real(mask_fg,kind=4)
!close(23)

! mask out area for computing statistics
DO k=1,nz
   WHERE(mask.EQ.0)
      area(:,:,k)=0.0
   ENDWHERE
ENDDO
! zero out increment in masked area
WHERE(area.EQ.0)
   pt_inc=0
   s_inc=0
ENDWHERE
print*,'maxval area=',maxval(area)
print*,'min/max s_fg',minval(s_fg),maxval(s_fg)
inv_sumwt=1.0/(SUM(area))
inv_sumwt2d=1.0/(SUM(area(:,:,1)))
varname='pt_inc'
call compute_stats(pt_inc,varname,area,inv_sumwt,nxa,nya,nz,fid)
varname='s_inc'
call compute_stats(s_inc,varname,area,inv_sumwt,nxa,nya,nz,fid)
varname='SSH'
call compute_stats2d(ssh_fg,varname,area(:,:,1),inv_sumwt2d,nxa,nya,fid)
varname='Salinity'
call compute_stats(s_fg,varname,area,inv_sumwt,nxa,nya,nz,fid)
varname='Temperature'
call compute_stats(pt_fg,varname,area,inv_sumwt,nxa,nya,nz,fid)
close (fid)
! interpolate back to first guess grid

call interp_3d(pt_inc,pt_inc_out,S2,col2,row2,n_s2,nxa,nya,nz,nx,ny)
call interp_3d(s_inc,s_inc_out,S2,col2,row2,n_s2,nxa,nya,nz,nx,ny)

! apply mask again
DO i=1,nz
   WHERE(mask_fgi .NE. 1.0)
        pt_inc_out(:,:,i)=0.0
        s_inc_out(:,:,i)=0.0
   ENDWHERE
ENDDO
call check(NF90_PUT_VAR(ncid_inc,varid1,pt_inc_out),cct)
call check(NF90_PUT_VAR(ncid_inc,varid2,s_inc_out),cct)
call check(NF90_PUT_VAR(ncid_inc,varid3,h_fg),cct) ! first guess thicknesses
call check(NF90_CLOSE(ncid_inc),cct)

!print*,' mask in',minval(mask_fgi),maxval(mask_fgi)
!print*,' mask interp',minval(area(:,:,1)),maxval(area(:,:,1))
!print*,' mask anl',minval(mask_anl(:,:)),maxval(mask_anl(:,:))

end


! error handling for netCDF calls
subroutine check(status,ct)
integer,intent(in) :: status
integer,intent(inout) :: ct
   include 'netcdf.inc'
!   print*,'ct=',ct
if(status /= 0) then
    print*,' check netcdf status=',status,ct
    STOP 99
endif
ct=ct+1
end subroutine check
subroutine compute_stats(incdata,varname,area, inv_sumwt, nlons,nlats,nlevs,fid)
  use netcdf
  implicit none
  integer, intent(in) :: nlons,nlats,nlevs
  real(kind=8), intent(in) ::  incdata(nlons,nlats,nlevs)
  real(kind=8), intent(in) ::  area(nlons,nlats,nlevs)
  real(kind=8), intent(in) :: inv_sumwt
  real(kind=8)             :: mn,mse
  character(len=nf90_max_name), intent(in) :: varname
  integer,      intent(in) :: fid
! compute area weighted global mean and rms
  mn=0.0
  mse=0.0
  mn = SUM(incdata(:,:,:)*area(:,:,:))*inv_sumwt
  mse =sqrt(SUM((incdata(:,:,:)**2)*area(:,:,:))*inv_sumwt)
  write(fid,'(2A,2(A,e12.3))')  'Mean and RMS of, ',trim(adjustl(varname)),',',real(mn,kind=4),',',real(mse,kind=4)
  print*,'Min/Max of ',trim(adjustl(varname)),minval(incdata),maxval(incdata)
end subroutine compute_stats
subroutine compute_stats2d(incdata,varname,area, inv_sumwt, nlons,nlats,fid)
  use netcdf
  implicit none
  integer, intent(in) :: nlons,nlats
  real(kind=8), intent(in) ::  incdata(nlons,nlats)
  real(kind=8), intent(in) ::  area(nlons,nlats)
  real(kind=8), intent(in) :: inv_sumwt
  real(kind=8)             :: mn,mse
  character(len=nf90_max_name), intent(in) :: varname
  integer,      intent(in) :: fid
! compute area weighted global mean and rms
  mn=0.0
  mse=0.0
  mn = SUM(incdata(:,:)*area(:,:))*inv_sumwt
  mse =sqrt(SUM((incdata(:,:)**2)*area(:,:))*inv_sumwt)
  write(fid,'(2A,2(A,e12.3))')  'Mean and RMS of, ',trim(adjustl(varname)),',',real(mn,kind=4),',',real(mse,kind=4)
  print*,'Min/Max of ',trim(adjustl(varname)),minval(incdata),maxval(incdata)
end subroutine compute_stats2d


