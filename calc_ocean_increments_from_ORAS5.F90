program  calc_oras5_incrment

use netcdf

implicit none
integer                 :: ncid_fg,ncid_anl,ncid_inc,varid,dimid
integer                 :: xt_dim_id,yt_dim_id,xt_var_id,yt_var_id
integer                 :: xq_dim_id,yq_dim_id,xq_var_id,yq_var_id
integer                 :: varid1,varid2,varid3,varid4,varid5,varid_lon,varid_lat
integer                 :: zl_dim_id,zl_var_id,ierr,fid

include 'netcdf.inc'

integer     :: i,j,k,nx,ny,nz,nx2,ny2,nz2,cct,nargs,iforcing_factor
integer     :: i1,i2,j1,j2
character*80 :: fname_fg,fname_anl,fname_inc
character*240 :: path_fg,path_anl

real(kind=8),allocatable,dimension(:,:) :: ssh_anl,ssh_inc,tmp2d,areaS
real(kind=8),allocatable,dimension(:,:,:) :: pt_anl ,pt_inc,tmp3d
real(kind=8),allocatable,dimension(:,:,:) :: s_anl ,s_inc,area
real(kind=8),allocatable,dimension(:,:,:) :: u_anl ,u_inc
real(kind=8),allocatable,dimension(:,:,:) :: v_anl ,v_inc
real,allocatable,dimension(:,:) :: ssh_fg , mask
real,allocatable,dimension(:,:,:) :: pt_fg,h_fg,s_fg,u_fg,v_fg,depth

real,allocatable,dimension(:) :: z_anl,z_fg
real(kind=8),allocatable,dimension(:) :: lath,lonh,latq,lonq,new_prof
real(kind=8) :: inv_sumwt2d,inv_sumwt,undef
character(len=nf90_max_name) :: varname
character*10 :: analdate
character*240 :: expt,oras5path
character*4 :: yyyy
character*2 :: mm,dd
character*3 charnin
real forcing_factor

undef=-1.e+34

nargs=iargc()
if (nargs.EQ.3) then
   call getarg(1,analdate)
   call getarg(2,expt)
   call getarg(3,oras5path)
   forcing_factor=1.0
else if (nargs.EQ.4) then
   call getarg(1,analdate)
   call getarg(2,expt)
   call getarg(3,oras5path)
   call getarg(4,charnin)
   read(charnin,'(i3)') iforcing_factor ! percent
   forcing_factor=iforcing_factor/100.
else
   print*,'usage calc_increment <date> <expt path> <oras5 path> <iau_forcing_factor>'
   STOP
endif
yyyy=analdate(1:4)
mm=analdate(5:6)
dd=analdate(7:8)

! open up MOM6 bg file to get grid info
path_fg=trim(expt)//'/'
fname_fg='ocn_'//yyyy//'_'//mm//'_'//dd//'_12.nc'
path_anl=trim(oras5path)//'/'
fname_anl='ORAS5.mx025_'//yyyy//mm//dd//'.ic.nc'
fname_inc='mom6_increment.nc'

fid=33
open (fid,file=trim(path_fg)//'logs/calc_ocn_inc.out')
cct=1
print*,'iau_forcing_factor=',forcing_factor
print*,'opening',trim(path_fg)//'control/INPUT/ocean_hgrid.nc'
call check(NF90_OPEN(trim(path_fg)//'control/INPUT/ocean_hgrid.nc',NF90_NOWRITE,ncid_fg),cct)
call check(NF90_INQ_DIMID(ncid_fg,'nx',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nx),cct)
call check(NF90_INQ_DIMID(ncid_fg,'ny',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=ny),cct)
allocate(areaS(nx,ny))
call check(NF90_INQ_VARID(ncid_fg,'area',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,areaS(:,:)),cct)

print*,'opening',trim(path_fg)//trim(fname_fg)
call check(NF90_OPEN(trim(path_fg)//trim(fname_fg),NF90_NOWRITE,ncid_fg),cct)
! get dimensions
call check(NF90_INQ_DIMID(ncid_fg,'xh',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nx),cct)
call check(NF90_INQ_DIMID(ncid_fg,'yh',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=ny),cct)
call check(NF90_INQ_DIMID(ncid_fg,'z_l',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg,dimid,len=nz),cct)
!print*,'fg size is',nx,ny,nz
! allocate arrays

! create a mask to zero out increments over the black sea
allocate(mask(nx,ny))
mask=1.0
if (nx .EQ. 1440) then
   ! resolution is 0.25 degrees 
   mask(1312:1367,685:717)=0.0
   mask(1353:1367,684)=0.0
else if (nx .EQ. 360) then
   mask(329:342,215:222)=0.0
   mask(337:342,214)=0.0
   ! resolution is 1.00 degrees 
else
   print*,'resolution not supported',360.0/nx
   stop 1
endif

allocate(lonh(nx))
allocate(lonq(nx))
allocate(lath(ny))
allocate(latq(ny))

allocate(tmp2d(nx,ny))
allocate(tmp3d(nx,ny,nz))
allocate(pt_fg(nx,ny,nz))
allocate(pt_anl(nx,ny,nz))
allocate(pt_inc(nx,ny,nz))
allocate(s_fg(nx,ny,nz))
allocate(s_anl(nx,ny,nz))
allocate(s_inc(nx,ny,nz))
allocate(u_fg(nx,ny,nz))
allocate(u_anl(nx,ny,nz))
allocate(u_inc(nx,ny,nz))
allocate(v_fg(nx,ny,nz))
allocate(v_anl(nx,ny,nz))
allocate(v_inc(nx,ny,nz))
allocate(h_fg(nx,ny,nz))
allocate(ssh_fg(nx,ny))
allocate(ssh_anl(nx,ny))
allocate(ssh_inc(nx,ny))
allocate(z_anl(nz))
allocate(z_fg(nz))
allocate(depth(nx,ny,nz))
allocate(new_prof(nz))
allocate(area(nx,ny,nz))
! get F.G. fields
call check(NF90_INQ_VARID(ncid_fg,'SSH',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,ssh_fg(:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg,'temp',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,pt_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg,'ho',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,h_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg,'so',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,s_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg,'uo',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,u_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg,'vo',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,v_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg,'z_l',varid),cct)
call check(NF90_GET_VAR(ncid_fg,varid,z_fg(:)),cct)
call check(NF90_CLOSE(ncid_fg),cct)

! define incrment files
!print*,'creating',trim(fname_inc)
!call check(NF90_CREATE(trim(fname_inc),cmode=NF90_CLOBBER,ncid=ncid_inc),cct)
call check(NF90_CREATE(trim(fname_inc),cmode=or(nf90_clobber,nf90_64bit_offset),ncid=ncid_inc),cct)
call check(NF90_DEF_DIM(ncid_inc,"lonh",nx,xt_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"lath",ny,yt_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"lonq",nx,xq_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"latq",ny,yq_dim_id),cct)
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
call check(NF90_DEF_VAR(ncid_inc,"lonq",NF90_DOUBLE,(/ xq_dim_id /), xq_var_id),cct)
call check(NF90_PUT_ATT(ncid_inc,xq_var_id,"long_name","Longitude"),cct)
call check(NF90_PUT_ATT(ncid_inc,xq_var_id,"cartesian_axis","X"),cct)

call check(NF90_PUT_ATT(ncid_inc,xq_var_id,"units","degrees_E"),cct)
call check(NF90_DEF_VAR(ncid_inc,"latq",NF90_DOUBLE,(/ yq_dim_id /), yq_var_id),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"long_name","Latitude"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"cartesian_axis","Y"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"units","degrees_N"),cct)
call check(NF90_DEF_VAR(ncid_inc,"Layer",NF90_DOUBLE,(/ zl_dim_id /), zl_var_id),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"long_name","Depth at cell center"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"cartesian_axis","Z"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"units","meter"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"positive","down"),cct)


call check(NF90_DEF_VAR(ncid_inc,"pt_inc",NF90_DOUBLE,(/xt_dim_id, yt_dim_id ,zl_dim_id/), varid1),cct)
call check(NF90_PUT_ATT(ncid_inc,varid1,"long_name","ORAS5 Potential Temperature increments"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid1,"units","degC"),cct)
call check(NF90_DEF_VAR(ncid_inc,"s_inc",NF90_DOUBLE,(/xt_dim_id, yt_dim_id ,zl_dim_id/), varid2),cct)
call check(NF90_PUT_ATT(ncid_inc,varid2,"long_name","ORAS5 Salinity increments"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid2,"units","PPT"),cct)
call check(NF90_DEF_VAR(ncid_inc,"h_fg",NF90_DOUBLE,(/xt_dim_id, yt_dim_id ,zl_dim_id/), varid3),cct)
call check(NF90_PUT_ATT(ncid_inc,varid3,"long_name","Background thickness"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid3,"units","m"),cct)
call check(NF90_DEF_VAR(ncid_inc,"u_inc",NF90_DOUBLE,(/xq_dim_id, yt_dim_id ,zl_dim_id/), varid4),cct)
call check(NF90_PUT_ATT(ncid_inc,varid4,"long_name","ORAS5 Zonal velocity increments"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid4,"units","m s-1"),cct)
call check(NF90_DEF_VAR(ncid_inc,"v_inc",NF90_DOUBLE,(/xt_dim_id, yq_dim_id, zl_dim_id /), varid5),cct)
call check(NF90_PUT_ATT(ncid_inc,varid5,"long_name","ORAS5 Meridional velocity increments"),cct)
call check(NF90_PUT_ATT(ncid_inc,varid5,"units","m"),cct)
call check(NF90_ENDDEF(ncid_inc),cct)


! read in analysis (ORAS5)
print*,'opening',trim(path_anl)//trim(fname_anl)
call check(NF90_OPEN(trim(path_anl)//trim(fname_anl),NF90_NOWRITE,ncid_anl),cct)
! get dimensions
call check(NF90_INQ_DIMID(ncid_anl,'lonh',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_anl,dimid,len=nx2),cct)
call check(NF90_INQ_DIMID(ncid_anl,'lath',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_anl,dimid,len=ny2),cct)
call check(NF90_INQ_DIMID(ncid_anl,'Layer',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_anl,dimid,len=nz2),cct)
!print*,'analysis size is',nx2,ny2,nz2
! check dimension
ierr=0
if (nx .NE. nx2) then
    print*,'x-dimension does not match.  ANL:',nx2,' FG:',nx
    ierr=1
endif
if (ny .NE. ny2) then
    print*,'y-dimension does not match.  ANL:',ny2,' FG:',ny
    ierr=1
endif
if (nz .NE. nz2) then
    print*,'z-dimension does not match.  ANL:',nz2,' FG:',nz
    ierr=1
endif
if (ierr.NE.0) STOP
! get grid
call check(NF90_INQ_VARID(ncid_anl,'lonh',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,lonh(:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'lath',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,lath(:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'lonq',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,lonq(:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'latq',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,latq(:)),cct)

! get analysis fields
call check(NF90_INQ_VARID(ncid_anl,'sfc',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,ssh_anl(:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'Temp',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,pt_anl(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'Salt',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,s_anl(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'u',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,u_anl(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'v',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,v_anl(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'Layer',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,z_anl(:)),cct)
! make z_anl negative
z_anl(:)=-1.0*z_anl(:)
call check(NF90_CLOSE(ncid_anl),cct)

! write grid info to netcdf file

call check(NF90_PUT_VAR(ncid_inc,xt_var_id,lonh),cct)
call check(NF90_PUT_VAR(ncid_inc,yt_var_id,lath),cct)
call check(NF90_PUT_VAR(ncid_inc,xq_var_id,lonq),cct)
call check(NF90_PUT_VAR(ncid_inc,yq_var_id,latq),cct)
call check(NF90_PUT_VAR(ncid_inc,zl_var_id,z_fg),cct)
! compute incrments
ssh_inc(:,:)=forcing_factor*(ssh_anl(:,:) - ssh_fg(:,:))
pt_inc(:,:,:)=forcing_factor*(pt_anl(:,:,:) - pt_fg(:,:,:))
s_inc(:,:,:)=forcing_factor*(s_anl(:,:,:) - s_fg(:,:,:))
u_inc(:,:,:)=forcing_factor*(u_anl(:,:,:) - u_fg(:,:,:))
v_inc(:,:,:)=forcing_factor*(v_anl(:,:,:) - v_fg(:,:,:))

!aggregate area to A-grid
DO j=1,ny/2
   j1=(j-1)*2+1
   j2=j1+1
   DO i=1,nx/2
      i1=(i-1)*2+1
      i2=i1+1
      area(i,j,:)=areaS(i1,j1)+areaS(i1,j2)+areaS(i2,j1)+areaS(i2,j2)
   ENDDO
ENDDO
deallocate(areaS)

! mask out missing values
WHERE(pt_fg .LT. -2.0 .OR. pt_fg .GT. 50)
   pt_inc=0.0
   s_inc=0.0
   u_inc=0.0
   v_inc=0.0
ENDWHERE
! mask out Black sea
DO k=1,nz
  pt_inc(:,:,k)=pt_inc(:,:,k)*mask
  s_inc(:,:,k)=s_inc(:,:,k)*mask
  u_inc(:,:,k)=u_inc(:,:,k)*mask
  v_inc(:,:,k)=v_inc(:,:,k)*mask
ENDDO
! use temperature as a mask for stats
WHERE(pt_fg .EQ. -1.e+34)
   area=0.0
ENDWHERE
WHERE(area.EQ.0)
   pt_fg=0
   s_fg=0
   u_fg=0
   v_fg=0
ENDWHERE
WHERE(area(:,:,1).EQ.0)
   ssh_fg=0
ENDWHERE
inv_sumwt=1.0/(SUM(area))
inv_sumwt2d=1.0/(SUM(area(:,:,1)))
varname='pt_inc'
call compute_stats(pt_inc,varname,area,inv_sumwt,nx,ny,nz,fid)
varname='s_inc'
call compute_stats(s_inc,varname,area,inv_sumwt,nx,ny,nz,fid)
varname='u_inc'
call compute_stats(u_inc,varname,area,inv_sumwt,nx,ny,nz,fid)
varname='v_inc'
call compute_stats(v_inc,varname,area,inv_sumwt,nx,ny,nz,fid)
varname='SSH'
call compute_stats2d(real(ssh_fg,kind=8),varname,area(:,:,1),inv_sumwt2d,nx,ny,fid)
varname='Salinity'
call compute_stats(real(s_fg,kind=8),varname,area,inv_sumwt,nx,ny,nz,fid)
varname='Temperature'
call compute_stats(real(pt_fg,kind=8),varname,area,inv_sumwt,nx,ny,nz,fid)
pt_fg=sqrt(u_fg**2+v_fg**2)
varname='Speed of Currents'
call compute_stats(real(pt_fg,kind=8),varname,area,inv_sumwt,nx,ny,nz,fid)
close (fid)

! interpolate to first guess depth
depth(:,:,1)=ssh_fg(:,:)-0.5*h_fg(:,:,1)
do k=2,nz
   depth(:,:,k)=ssh_fg(:,:)-(0.5*h_fg(:,:,k)+SUM(h_fg(:,:,1:k-1),3))
enddo
call interp1( pt_inc,s_inc,u_inc,v_inc,z_anl,depth,nx,ny,nz)

call check(NF90_PUT_VAR(ncid_inc,varid1,pt_inc),cct)
call check(NF90_PUT_VAR(ncid_inc,varid2,s_inc),cct)
call check(NF90_PUT_VAR(ncid_inc,varid3,h_fg),cct) ! first guess thicknesses
call check(NF90_PUT_VAR(ncid_inc,varid4,u_inc),cct)
call check(NF90_PUT_VAR(ncid_inc,varid5,v_inc),cct)
call check(NF90_CLOSE(ncid_inc),cct)
!open(30,file='t_inc.bin',form='unformatted',access='sequential')
!do k=1,nz
!  write(30) real(pt_inc(:,:,k),kind=4)
!enddo

end
subroutine check(status,ct)
integer,intent(in) :: status
integer,intent(inout) :: ct
   include 'netcdf.inc'
if(status /= 0) then
    print*,' check netcdf status=',status,ct
    STOP 99
endif
ct=ct+1
end subroutine check
subroutine interp1( tData, sData, uData, VData, xLoc, yLoc,nx,ny,nz )
! Inputs: xData = a vector of the x-values of the data to be interpolated
!         xLoc  = a vector of the x-values where interpolation should be
!         yLoc  = a vector of the x-values where interpolation should be
!         performed
! Output: yData = a vector of the resulting interpolated values

  implicit none

  real*8, intent(inout) :: tData(nx,ny,nz)
  real*8, intent(inout) :: sData(nx,ny,nz)
  real*8, intent(inout) :: uData(nx,ny,nz)
  real*8, intent(inout) :: vData(nx,ny,nz)
  real, intent(in) :: xLoc(nz),yLoc(nx,ny,nz)
  integer, intent(in) :: nx,ny,nz
  integer :: inputIndex, dataIndex,z,z2,i,j
  real :: weight
  real :: t_tmp(nz),s_tmp(nz),u_tmp(nz),v_tmp(nz)
  logical :: lprint


  ! this needs to work for depth going from surface to sea-floor and sea-floor
  ! is negative
  !print*,'before xLoc',xLoc(:)
  !print*,'before yLoc',yLoc(1,149,:)
  !DO z = 1, nz
  !    print*,'S & T',z,sData(211,197,z),tData(211,197,z) , uData(211,197,z),vData(211,197,z)
  !ENDDO
  lprint=.false.
  do j=1,ny
     do i=1,nx
!        lprint=.false.
!        if (i.EQ.211.AND.j.EQ.197) lprint=.true.

        t_tmp(:)=tData(i,j,:)
        s_tmp(:)=sData(i,j,:)
        u_tmp(:)=uData(i,j,:)
        v_tmp(:)=vData(i,j,:)
        do z = 1, nz
           if (yLoc(i,j,z) > xLoc(1)) then !extrapolate increment to surface
              tData(i,j,z) = t_tmp(1)
              sData(i,j,z) = s_tmp(1)
              uData(i,j,z) = u_tmp(1)
              vData(i,j,z) = v_tmp(1)
              if (lprint) print*,'top     ',z,yLoc(i,j,z),xLoc(1),s_tmp(1)
           else if (yLoc(i,j,z) < xLoc(nz)) then !extrapolate increment to surface
              tData(i,j,z) = t_tmp(nz)
              sData(i,j,z) = s_tmp(nz)
              uData(i,j,z) = u_tmp(nz)
              vData(i,j,z) = v_tmp(nz)
              if (lprint) print*,'bottom  ',z,yLoc(i,j,z),xLoc(nz),s_tmp(nz)
           else ! find layer just above taget layer
              do z2 = 1, nz
                 if (yLoc(i,j,z) < xLoc(z2)) cycle
                 weight = (yLoc(i,j,z) - xLoc(z2))/(xLoc(z2-1)-xLoc(z2))
                 !tData(i,j,z) = (1.0-weight)*t_tmp(z2-1) + weight*t_tmp(z2)
                 !sData(i,j,z) = (1.0-weight)*s_tmp(z2-1) + weight*s_tmp(z2)
                 !uData(i,j,z) = (1.0-weight)*u_tmp(z2-1) + weight*u_tmp(z2)
                 !vData(i,j,z) = (1.0-weight)*v_tmp(z2-1) + weight*v_tmp(z2)
                 tData(i,j,z) = (1.0-weight)*t_tmp(z2) + weight*t_tmp(z2-1)
                 sData(i,j,z) = (1.0-weight)*s_tmp(z2) + weight*s_tmp(z2-1)
                 uData(i,j,z) = (1.0-weight)*u_tmp(z2) + weight*u_tmp(z2-1)
                 vData(i,j,z) = (1.0-weight)*v_tmp(z2) + weight*v_tmp(z2-1)
                 if (lprint) print*,'interp ',z,yLoc(i,j,z),xLoc(z2),weight,z2,sData(i,j,z),s_tmp(z2-1),s_tmp(z2)
                 exit
              end do
           endif
        end do
     end do
  end do
end subroutine
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
  !print*,'MAX/MIN',minval(incdata),maxval(incdata)
  !print*,'MAX/MIN',minval(incdata*area),maxval(incdata*area)
end subroutine compute_stats2d


