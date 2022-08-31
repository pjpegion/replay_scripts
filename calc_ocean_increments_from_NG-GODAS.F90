program  calc_ng_godas_incrment

use netcdf

implicit none
integer                 :: ncid_fg1,ncid_fg2,ncid_anl,ncid_inc,varid,dimid
integer                 :: xt_dim_id,yt_dim_id,xt_var_id,yt_var_id
integer                 :: xq_dim_id,yq_dim_id,xq_var_id,yq_var_id
integer                 :: varid1,varid2,varid3,varid4,varid5,varid_lon,varid_lat
integer                 :: zl_dim_id,zl_var_id,ierr

include 'netcdf.inc'

integer     :: i,j,k,nx,ny,nz,nx2,ny2,nz2,cct,nargs,iforcing_factor
character*80 :: fname_fg1,fname_fg2,fname_anl,fname_inc
character*240 :: path_fg,path_anl

real(kind=8),allocatable,dimension(:,:) :: ssh_inc,tmp2d
real(kind=8),allocatable,dimension(:,:,:) :: ssh_anl,pt_inc,tmp3d
real(kind=8),allocatable,dimension(:,:,:) :: s_inc
real(kind=8),allocatable,dimension(:,:,:) :: u_inc
real(kind=8),allocatable,dimension(:,:,:) :: v_inc
real(kind=8),allocatable,dimension(:,:,:,:) :: pt_anl,s_anl,u_anl,v_anl,h_anl
real,allocatable,dimension(:,:) :: ssh_fg 
real,allocatable,dimension(:,:,:) :: pt_fg,h_fg,s_fg,u_fg,v_fg,depth,z_anl

real,allocatable,dimension(:) :: z_fg
real(kind=8),allocatable,dimension(:) :: lath,lonh,latq,lonq,new_prof
character*10 :: analdate,analdatem2,analdatep1
character*240 :: expt,anlpath
character*4 :: yyyy
character*2 :: mm,dd,hh
character*3 charnin
real forcing_factor

nargs=iargc()
if (nargs.EQ.5) then
   call getarg(1,analdate)
   call getarg(2,analdatem2)
   call getarg(3,analdatep1)
   call getarg(4,expt)
   call getarg(5,anlpath)
   forcing_factor=1.0
else if (nargs.EQ.6) then
   call getarg(1,analdate)
   call getarg(2,analdatem2)
   call getarg(3,analdatep1)
   call getarg(4,expt)
   call getarg(5,anlpath)
   call getarg(6,charnin)
   read(charnin,'(i3)') iforcing_factor ! percent
   forcing_factor=iforcing_factor/100.
else
   print*,'usage calc_increment <date> <date-2hrs> <date+1hr> <expt path> <analysis path> <iau_forcing_factor>'
   STOP
endif
path_fg=trim(expt)//'/'
! ocean history file date 1 hour before nomimal analysis time (really 1.5 hours)
yyyy=analdatem2(1:4)
mm=analdatem2(5:6)
dd=analdatem2(7:8)
hh=analdatem2(9:10)
fname_fg1='ocn_'//yyyy//'_'//mm//'_'//dd//'_10.nc'

! ocean history file date 2 hours after nomimal analysis time (really 1.5 hours)
yyyy=analdatep1(1:4)
mm=analdatep1(5:6)
dd=analdatep1(7:8)
hh=analdatep1(9:10)
fname_fg1='ocn_'//yyyy//'_'//mm//'_'//dd//'_10.nc'
fname_fg2='ocn_'//yyyy//'_'//mm//'_'//dd//'_13.nc'
path_anl=trim(anlpath)//'/'//analdate//'/'
fname_anl='ocn.ana.'//analdate//'.nc'

fname_inc='nggodas_increment.nc'
cct=1
print*,'iau_forcing_factor=',forcing_factor
print*,'opening',trim(path_fg)//trim(fname_fg1)
call check(NF90_OPEN(trim(path_fg)//trim(fname_fg1),NF90_NOWRITE,ncid_fg1),cct)
print*,'opening',trim(path_fg)//trim(fname_fg2)
call check(NF90_OPEN(trim(path_fg)//trim(fname_fg2),NF90_NOWRITE,ncid_fg2),cct)
! get dimensions
call check(NF90_INQ_DIMID(ncid_fg1,'xh',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg1,dimid,len=nx),cct)
call check(NF90_INQ_DIMID(ncid_fg1,'yh',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg1,dimid,len=ny),cct)
call check(NF90_INQ_DIMID(ncid_fg1,'zl',dimid),cct)
call check(NF90_INQUIRE_DIMENSION(ncid_fg1,dimid,len=nz),cct)
print*,'fg1 size is',nx,ny,nz
! allocate arrays
allocate(lonh(nx))
allocate(lonq(nx))
allocate(lath(ny))
allocate(latq(ny))

allocate(tmp2d(nx,ny))
allocate(tmp3d(nx,ny,nz))
allocate(pt_fg(nx,ny,nz))
allocate(pt_anl(nx,ny,nz,1))
allocate(pt_inc(nx,ny,nz))
allocate(s_fg(nx,ny,nz))
allocate(s_anl(nx,ny,nz,1))
allocate(s_inc(nx,ny,nz))
allocate(u_fg(nx,ny,nz))
allocate(u_anl(nx,ny,nz,1))
allocate(u_inc(nx,ny,nz))
allocate(v_fg(nx,ny,nz))
allocate(v_anl(nx,ny,nz,1))
allocate(v_inc(nx,ny,nz))
allocate(h_fg(nx,ny,nz))
allocate(ssh_fg(nx,ny))
allocate(ssh_anl(nx,ny,1))
allocate(h_anl(nx,ny,nz,1))
allocate(ssh_inc(nx,ny))
allocate(z_anl(nx,ny,nz))
allocate(z_fg(nz))
allocate(depth(nx,ny,nz))
allocate(new_prof(nz))

! get F.G. fields
call check(NF90_INQ_VARID(ncid_fg1,'SSH',varid),cct)
print*,'get ssh 1',cct
call check(NF90_GET_VAR(ncid_fg1,varid,ssh_fg(:,:)),cct)
print*,'got ssh 1',cct
call check(NF90_INQ_VARID(ncid_fg2,'SSH',varid),cct)
print*,'get ssh 2',cct
call check(NF90_GET_VAR(ncid_fg2,varid,tmp2d(:,:)),cct)
print*,'got ssh 2',cct
ssh_fg(:,:)=(ssh_fg(:,:)+tmp2d(:,:))/2.0
call check(NF90_INQ_VARID(ncid_fg1,'temp',varid),cct)
print*,'get temp 1',cct
call check(NF90_GET_VAR(ncid_fg1,varid,pt_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg2,'temp',varid),cct)
call check(NF90_GET_VAR(ncid_fg2,varid,tmp3d(:,:,:)),cct)
pt_fg(:,:,:)=(pt_fg(:,:,:)+tmp3d(:,:,:))/2.0
call check(NF90_INQ_VARID(ncid_fg1,'ho',varid),cct)
call check(NF90_GET_VAR(ncid_fg1,varid,h_fg(:,:,:)),cct)
print*,'5' 
call check(NF90_INQ_VARID(ncid_fg2,'ho',varid),cct)
call check(NF90_GET_VAR(ncid_fg2,varid,tmp3d(:,:,:)),cct)
h_fg(:,:,:)=(h_fg(:,:,:)+tmp3d(:,:,:))/2.0
call check(NF90_INQ_VARID(ncid_fg1,'so',varid),cct)
call check(NF90_GET_VAR(ncid_fg1,varid,s_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg2,'so',varid),cct)
call check(NF90_GET_VAR(ncid_fg2,varid,tmp3d(:,:,:)),cct)
s_fg(:,:,:)=(s_fg(:,:,:)+tmp3d(:,:,:))/2.0
call check(NF90_INQ_VARID(ncid_fg1,'uo',varid),cct)
call check(NF90_GET_VAR(ncid_fg1,varid,u_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg2,'uo',varid),cct)
call check(NF90_GET_VAR(ncid_fg2,varid,tmp3d(:,:,:)),cct)
u_fg(:,:,:)=(u_fg(:,:,:)+tmp3d(:,:,:))/2.0
call check(NF90_INQ_VARID(ncid_fg1,'vo',varid),cct)
call check(NF90_GET_VAR(ncid_fg1,varid,v_fg(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_fg2,'vo',varid),cct)
call check(NF90_GET_VAR(ncid_fg2,varid,tmp3d(:,:,:)),cct)
v_fg(:,:,:)=(v_fg(:,:,:)+tmp3d(:,:,:))/2.0
call check(NF90_INQ_VARID(ncid_fg1,'z_l',varid),cct)
call check(NF90_GET_VAR(ncid_fg1,varid,z_fg(:)),cct)
call check(NF90_CLOSE(ncid_fg1),cct)
print*,'6' 

! define incrment files
!print*,'creating',trim(fname_inc)
!call check(NF90_CREATE(trim(fname_inc),cmode=NF90_CLOBBER,ncid=ncid_inc),cct)
call check(NF90_CREATE(trim(fname_inc),cmode=or(nf90_clobber,nf90_64bit_offset),ncid=ncid_inc),cct)
call check(NF90_DEF_DIM(ncid_inc,"lonh",nx,xt_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"lath",ny,yt_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"lonq",nx,xq_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"latq",ny,yq_dim_id),cct)
call check(NF90_DEF_DIM(ncid_inc,"Layer",nz,zl_dim_id),cct)
  !> - Define the dimension variables.Q
!NG-GODAS files are missing the variable latq, so I will comment out all of the
!grid definition files
!call check(NF90_DEF_VAR(ncid_inc,"lonh",NF90_DOUBLE,(/ xt_dim_id /), xt_var_id),cct)
!call check(NF90_PUT_ATT(ncid_inc,xt_var_id,"long_name","Longitude"),cct)
!call check(NF90_PUT_ATT(ncid_inc,xt_var_id,"cartesian_axis","X"),cct)
!call check(NF90_PUT_ATT(ncid_inc,xt_var_id,"units","degrees_E"),cct)
!call check(NF90_DEF_VAR(ncid_inc,"lath",NF90_DOUBLE,(/ yt_dim_id /), yt_var_id),cct)
!call check(NF90_PUT_ATT(ncid_inc,yt_var_id,"long_name","Latitude"),cct)
!call check(NF90_PUT_ATT(ncid_inc,yt_var_id,"cartesian_axis","Y"),cct)
!call check(NF90_PUT_ATT(ncid_inc,yt_var_id,"units","degrees_N"),cct)
!call check(NF90_DEF_VAR(ncid_inc,"lonq",NF90_DOUBLE,(/ xq_dim_id /), xq_var_id),cct)
!call check(NF90_PUT_ATT(ncid_inc,xq_var_id,"long_name","Longitude"),cct)
!call check(NF90_PUT_ATT(ncid_inc,xq_var_id,"cartesian_axis","X"),cct)
!print*,'7' 
!call check(NF90_PUT_ATT(ncid_inc,xq_var_id,"units","degrees_E"),cct)
!call check(NF90_DEF_VAR(ncid_inc,"latq",NF90_DOUBLE,(/ yq_dim_id /), yq_var_id),cct)
!call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"long_name","Latitude"),cct)
!call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"cartesian_axis","Y"),cct)
!call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"units","degrees_N"),cct)
call check(NF90_DEF_VAR(ncid_inc,"Layer",NF90_DOUBLE,(/ zl_dim_id /), zl_var_id),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"long_name","Depth at cell center"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"cartesian_axis","Z"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"units","meter"),cct)
call check(NF90_PUT_ATT(ncid_inc,yq_var_id,"positive","down"),cct)

print*,'8' 
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
print*,'9' 
call check(NF90_ENDDEF(ncid_inc),cct)
print*,'10' 


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
!call check(NF90_INQ_VARID(ncid_anl,'lonh',varid),cct)
!call check(NF90_GET_VAR(ncid_anl,varid,lonh(:)),cct)
!call check(NF90_INQ_VARID(ncid_anl,'lath',varid),cct)
!call check(NF90_GET_VAR(ncid_anl,varid,lath(:)),cct)
!call check(NF90_INQ_VARID(ncid_anl,'lonq',varid),cct)
!call check(NF90_GET_VAR(ncid_anl,varid,lonq(:)),cct)
!call check(NF90_INQ_VARID(ncid_anl,'latq',varid),cct)
!call check(NF90_GET_VAR(ncid_anl,varid,latq(:)),cct)

! get analysis fields
call check(NF90_INQ_VARID(ncid_anl,'ave_ssh',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,ssh_anl(:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'Temp',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,pt_anl(:,:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'Salt',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,s_anl(:,:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'u',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,u_anl(:,:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'v',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,v_anl(:,:,:,:)),cct)
call check(NF90_INQ_VARID(ncid_anl,'h',varid),cct)
call check(NF90_GET_VAR(ncid_anl,varid,h_anl(:,:,:,:)),cct)
call check(NF90_CLOSE(ncid_anl),cct)

! write grid info to netcdf file

!call check(NF90_PUT_VAR(ncid_inc,xt_var_id,lonh),cct)
!call check(NF90_PUT_VAR(ncid_inc,yt_var_id,lath),cct)
!call check(NF90_PUT_VAR(ncid_inc,xq_var_id,lonq),cct)
!call check(NF90_PUT_VAR(ncid_inc,yq_var_id,latq),cct)
call check(NF90_PUT_VAR(ncid_inc,zl_var_id,z_fg),cct)
! compute incrments
ssh_inc(:,:)=forcing_factor*(ssh_anl(:,:,1) - ssh_fg(:,:))
pt_inc(:,:,:)=forcing_factor*(pt_anl(:,:,:,1) - pt_fg(:,:,:))
s_inc(:,:,:)=forcing_factor*(s_anl(:,:,:,1) - s_fg(:,:,:))
u_inc(:,:,:)=forcing_factor*(u_anl(:,:,:,1) - u_fg(:,:,:))
v_inc(:,:,:)=forcing_factor*(v_anl(:,:,:,1) - v_fg(:,:,:))

! mask out missing values
print*,'shape of pt_fg',shape(pt_fg)
WHERE(pt_fg .LT. -2.0 .OR. pt_fg .GT. 50)
   pt_inc=0.0
   s_inc=0.0
   u_inc=0.0
   v_inc=0.0
ENDWHERE
print *,'min/max T_inc',minval(pt_inc),maxval(pt_inc)
print *,'min/max u_inc',minval(u_inc),maxval(u_inc)
print *,'min/max v_inc',minval(v_inc),maxval(v_inc)

! interpolate to first guess depth
depth(:,:,1)=ssh_fg(:,:)-0.5*h_fg(:,:,1)
z_anl(:,:,1)=ssh_anl(:,:,1)-0.5*h_anl(:,:,1,1)
do k=2,nz
   depth(:,:,k)=ssh_fg(:,:)-(0.5*h_fg(:,:,k)+SUM(h_fg(:,:,1:k-1),3))
   z_anl(:,:,k)=ssh_anl(:,:,1)-(0.5*h_anl(:,:,k,1)+SUM(h_anl(:,:,1:k-1,1),3))
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
  real, intent(in) :: xLoc(nx,ny,nz),yLoc(nx,ny,nz)
  integer, intent(in) :: nx,ny,nz
  integer :: inputIndex, dataIndex,z,z2,i,j
  real :: weight
  real :: t_tmp(nz),s_tmp(nz),u_tmp(nz),v_tmp(nz)
  logical :: lprint


  ! this needs to work for depth going from surface to sea-floor and sea-floor
  ! is negative
  print*,'before xLoc',xLoc(1,149,:)
  print*,'before yLoc',yLoc(1,149,:)
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
           if (yLoc(i,j,z) > xLoc(i,j,1)) then !extrapolate increment to surface
              tData(i,j,z) = t_tmp(1)
              sData(i,j,z) = s_tmp(1)
              uData(i,j,z) = u_tmp(1)
              vData(i,j,z) = v_tmp(1)
              if (lprint) print*,'top     ',z,yLoc(i,j,z),xLoc(i,j,1),s_tmp(1)
           else if (yLoc(i,j,z) < xLoc(i,j,nz)) then !extrapolate increment to surface
              tData(i,j,z) = t_tmp(nz)
              sData(i,j,z) = s_tmp(nz)
              uData(i,j,z) = u_tmp(nz)
              vData(i,j,z) = v_tmp(nz)
              if (lprint) print*,'bottom  ',z,yLoc(i,j,z),xLoc(i,j,nz),s_tmp(nz)
           else ! find layer just above taget layer
              do z2 = 1, nz
                 if (yLoc(i,j,z) < xLoc(i,j,z2)) cycle
                 weight = (yLoc(i,j,z) - xLoc(i,j,z2))/(xLoc(i,j,z2-1)-xLoc(i,j,z2))
                 !tData(i,j,z) = (1.0-weight)*t_tmp(z2-1) + weight*t_tmp(z2)
                 !sData(i,j,z) = (1.0-weight)*s_tmp(z2-1) + weight*s_tmp(z2)
                 !uData(i,j,z) = (1.0-weight)*u_tmp(z2-1) + weight*u_tmp(z2)
                 !vData(i,j,z) = (1.0-weight)*v_tmp(z2-1) + weight*v_tmp(z2)
                 tData(i,j,z) = (1.0-weight)*t_tmp(z2) + weight*t_tmp(z2-1)
                 sData(i,j,z) = (1.0-weight)*s_tmp(z2) + weight*s_tmp(z2-1)
                 uData(i,j,z) = (1.0-weight)*u_tmp(z2) + weight*u_tmp(z2-1)
                 vData(i,j,z) = (1.0-weight)*v_tmp(z2) + weight*v_tmp(z2-1)
                 if (lprint) print*,'interp ',z,yLoc(i,j,z),xLoc(i,j,z2),weight,z2,sData(i,j,z),s_tmp(z2-1),s_tmp(z2)
                 exit
              end do
           endif
        end do
     end do
  end do
end subroutine
