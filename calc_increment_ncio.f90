PROGRAM calc_increment_ncio
!$$$  main program documentation block
!
! program:  calc_increment_ncio
!
! prgmmr: whitaker         org: esrl/psd               date: 2019-02-23
!
! abstract:  difference two ncio files, write out increment netcdf increment
! file for ingest into FV3.  The data in increment file must be oriented
! from south to north and from top to bottom in the vertical.
! if dpres and delz are not in ncio files, increments are inferred from
! ps and T.
!
! program history log:
!   2019-02-12  Initial version.
!
! usage:
!   input files: filename_fg filename_anal (1st two command line args)
!
!   output files: filename_inc (3rd command line arg)

!   4th command line arg is logical for controlling whether microphysics
!   increment should not be computed. 
!   5th command line arg is logical for controlling whether delz
!   increment should not be computed
!   6th command line arg is logical for controlling whether humidity
!   and microphysics vars should be tapered to zero in stratosphere.
!   The vertical profile of the taper is controlled by ak_top and ak_bot.

!   If delp and/or delz are not in the background history files, then
!   their increments are inferred (from ps, T and humidity increments).
!
! attributes:
!   language: f95
!
! ifort -O3 -xHOST -I${NCIO_INC} -I${NETCDF}/include calc_increment_ncio.f90
! ${NCIO_LIB} ${W3NCO_LIB4} ${BACIO_LIB4} -L${NETCDF}/lib -lnetcdf -lnetcdff
!
!Currently Loaded Modules:
!  1) hpc/1.1.0   2) intel/18.0.5.274   3) hpc-intel/18.0.5.274   4)
!impi/2018.0.4   5) hpc-impi/2018.0.4   6) netcdf/4.7.4   7) w3emc/2.9.1   8)
!ncio/1.1.2   9) hdf5/1.10.6  10) zlib/1.2.11  11) png/1.6.35
!
!
![Philip.Pegion@hfe12 C96_replay_p8_atm_noqv]$ mpiifort -o
!exec_hera/calc_increment_ncio.x -O3 -xHOST -I${NCIO_INC} -I${NETCDF}/include
!calc_increment_ncio.f90 ${NCIO_LIB} ${W3EMC_LIB4} -L${NETCDF}/lib -lnetcdff
!-lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz
!$$$

  use module_ncio, only: open_dataset, create_dataset, read_attribute, &
                           Dataset, Dimension, close_dataset, &
                           read_vardata, write_attribute, write_vardata, &
                           has_var, has_attr, get_dim
  use netcdf

  implicit none

! Declare externals
  external :: write_ncdata3d

  character*500 filename_anal,filename_inc,filename_fg,logfile
  character*3 charnin
  character(len=nf90_max_name) :: ncvarname
  integer i,j,k,nvar,ndims,nlats,nlons,nlevs,iret,nlons2,nlats2,nlevs2
  real, allocatable, dimension(:)     :: lats_tmp, lats, lons, ak, bk, ilevs, levs,coslat1d
  real, allocatable, dimension(:,:)   :: values_2d_fg,values_2d_anal,values_2d_inc,&
                                         ps_fg, ps_anal,latwts
  real, allocatable, dimension(:,:,:) :: values_3d_fg,values_3d_anal,values_3d_inc,&
                                         taper_vert,q_fg, q_anal, tmp_fg, tmp_anal, delzb, delza
  type(Dataset) :: dset_anal,dset_fg
  type(Dimension) :: londim,latdim,levdim
  integer, dimension(3) :: dimid_3d
  integer, dimension(1) :: dimid_1d
  integer varid_lon,varid_lat,varid_lev,varid_ilev,varid_hyai,varid_hybi,&
          dimid_lon,dimid_lat,dimid_lev,dimid_ilev,ncfileid,ncstatus
  real*8  :: deg2rad,pi,inv_sumwt
  logical :: no_mpinc, no_delzinc, has_dpres, has_delz, taper_strat, taper_pbl, lexist
  real rd,rv,fv,grav,ak_bot,ak_top,bk_bot,bk_top,forcing_factor
  integer :: fid
  namelist /setup/ ak_top, ak_bot, bk_top, bk_bot, forcing_factor,&
                   taper_strat, taper_pbl, no_mpinc, no_delzinc
  pi     = 4.D0*ATAN(1.0)
  deg2rad = pi/180.0
  rd     = 2.8705e+2
  rv     = 4.6150e+2
  fv     = rv/rd-1.    ! used in virtual temperature equation 
  grav   = 9.80665
  ! defaults for namelist
  forcing_factor = 1.00
  no_mpinc = .true.
  no_delzinc = .false.
  taper_strat = .false.
  taper_strat = .false.
  ! damp humidity increments between these two levels if taper_strat=T
  ak_bot = 10000. ! units Pa
  ak_top = 5000.
  ! tapering near surface (if taper_pbl=T)
  bk_bot = 1.0
  bk_top = 0.95

  call getarg(1,filename_fg)    ! first guess ncio file
  call getarg(2,filename_anal)  ! analysis ncio file
  call getarg(3,filename_inc)   ! output increment file
  if (iargc()==4) then
     call getarg(4,logfile)   ! output increment file
     fid=34
  else
     ! just write stats to standard out
     fid=-1
  endif


  inquire(file='calc_increment_ncio.nml', exist=lexist)
  if ( lexist ) then
    open(file='calc_increment_ncio.nml', unit=92, status='old', &
         form='formatted', action='read', access='sequential')
    read(92,nml=setup)
    close(92)
  else
    write(6,*) 'calc_increment_ncio.nml does not exist and should, ABORT!'
    stop 99
  endif

  write(6,*)'CALC_INCREMENT_NCIO:'
  write(6,*)'filename_fg=',trim(filename_fg)
  write(6,*)'filename_anal=',trim(filename_anal)
  write(6,*)'filename_inc=',trim(filename_inc)
  write(6,*)'no_mpinc',no_mpinc
  write(6,*)'no_delzinc',no_delzinc
  write(6,*)'taper_strat',taper_strat
  if ( fid == 34) open (fid,file=trim(logfile))
  if (taper_strat) then
    write(6,*), 'ak_bot,ak_top',ak_bot,ak_top
  endif
  write(6,*)'taper_pbl',taper_pbl
  if (taper_pbl) then
    write(6,*), 'bk_bot,bk_top',bk_bot,bk_top
  endif
  write(6,*)'iau_forcing_factor',forcing_factor

  dset_fg = open_dataset(trim(filename_fg),errcode=iret)
  if (iret .ne. 0) then
    print *,'error opening ',trim(filename_fg)
    stop
  endif
  dset_anal = open_dataset(trim(filename_anal),errcode=iret)
  if (iret .ne. 0) then
    print *,'error opening ',trim(filename_anal)
    stop
  endif

  londim = get_dim(dset_fg,'grid_xt'); nlons = londim%len
  latdim = get_dim(dset_fg,'grid_yt'); nlats = latdim%len
  levdim = get_dim(dset_fg,'pfull');   nlevs = levdim%len
  londim = get_dim(dset_anal,'grid_xt'); nlons2 = londim%len
  latdim = get_dim(dset_anal,'grid_yt'); nlats2 = latdim%len
  levdim = get_dim(dset_anal,'pfull');   nlevs2 = levdim%len
  print *,'nlons,nlats,nlevs',nlons,nlats,nlevs
  print *,'nlons2,nlats2,nlevs2',nlons2,nlats2,nlevs2
  if ( nlons /= nlons2 .or. nlats /= nlats2 .or. &
      nlevs /= nlevs2) then
    print *,'expecting nlons,nlats,nlevs =',nlons,nlats,nlevs
    print *,'got nlons,nlats,nlevs =',nlons2,nlats2,nlevs2
    stop
  endif

  call read_vardata(dset_fg, 'grid_xt', lons)
  call read_vardata(dset_fg, 'grid_yt', lats_tmp)
  allocate(ak(nlevs+1),bk(nlevs+1),levs(nlevs),ilevs(nlevs+1),lats(nlats))
  call read_attribute(dset_fg, 'ak', ak)
  call read_attribute(dset_fg, 'bk', bk)
  lats = lats_tmp(nlats:1:-1)
  allocate(coslat1d(nlats))
  allocate(latwts(nlons,nlats))
  coslat1d= cos(deg2rad*lats)
  DO i=1,nlons
     latwts(i,:)=coslat1d
  ENDDO
  inv_sumwt=1.0/SUM(latwts)
  deallocate(coslat1d)
  if (lats(1) .gt. lats(nlats)) then
    print *,'error: code assumes lats in ncio files are N to S'
    stop
  endif
  deallocate(lats_tmp)

! create netcdf increment file.
  ncstatus = nf90_create(trim(filename_inc),           &
       cmode=ior(NF90_CLOBBER,NF90_NETCDF4),ncid=ncfileid)
  if (ncstatus /= nf90_noerr) then
     print *, 'error opening file ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_def_dim(ncfileid,'lon',nlons,dimid_lon)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lon dim ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_def_dim(ncfileid,'lat',nlats,dimid_lat)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lat dim ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_def_dim(ncfileid,'lev',nlevs,dimid_lev)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lev dim ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_def_dim(ncfileid,'ilev',nlevs+1,dimid_ilev)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating ilev dim ',trim(nf90_strerror(ncstatus))
     stop
  endif
  dimid_1d(1) = dimid_lon
  ncstatus = nf90_def_var(ncfileid,'lon',nf90_float,dimid_1d,   &
       & varid_lon)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lon ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_att(ncfileid,varid_lon,'units','degrees_east')
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lon units ',trim(nf90_strerror(ncstatus))
     stop
  endif
  dimid_1d(1) = dimid_lat
  ncstatus = nf90_def_var(ncfileid,'lat',nf90_float,dimid_1d,   &
       & varid_lat)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lat ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_att(ncfileid,varid_lat,'units','degrees_north')
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lat units ',trim(nf90_strerror(ncstatus))
     stop
  endif
  dimid_1d(1) = dimid_lev
  ncstatus = nf90_def_var(ncfileid,'lev',nf90_float,dimid_1d,   &
       & varid_lev)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating lev ',trim(nf90_strerror(ncstatus))
     stop
  endif
  dimid_1d(1) = dimid_ilev
  ncstatus = nf90_def_var(ncfileid,'ilev',nf90_float,dimid_1d,  &
       & varid_ilev)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating ilev ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_def_var(ncfileid,'hyai',nf90_float,dimid_1d,  &
       & varid_hyai)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating hyai ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_def_var(ncfileid,'hybi',nf90_float,dimid_1d,  &
       & varid_hybi)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating hybi ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_att(ncfileid,nf90_global,'source','GSI')
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating global attribute source',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_att(ncfileid,nf90_global,'comment','global analysis increment from calc_increment_ncio')
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating global attribute comment',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_enddef(ncfileid)
  if (ncstatus /= nf90_noerr) then
     print *,'enddef error ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_var(ncfileid,varid_lon,lons)
  if (ncstatus /= nf90_noerr) then
     print *, 'error writing lon ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_var(ncfileid,varid_lat,lats)
  if (ncstatus /= nf90_noerr) then
     print *, 'error writing lat ',trim(nf90_strerror(ncstatus))
     stop
  endif
  do k=1,nlevs
     levs(k)=k
  enddo
  ncstatus = nf90_put_var(ncfileid,varid_lev,levs)
  if (ncstatus /= nf90_noerr) then
     print *, 'error writing lev ',trim(nf90_strerror(ncstatus))
     stop
  endif
  do k=1,nlevs+1
     ilevs(k)=k
  enddo
  ncstatus = nf90_put_var(ncfileid,varid_ilev,ilevs)
  if (ncstatus /= nf90_noerr) then
     print *, 'error writing ilev ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ! note that levels go from top to bottom (opposite to ncio files)
  ncstatus = nf90_put_var(ncfileid,varid_hyai,ak)
  if (ncstatus /= nf90_noerr) then
     print *, 'error writing hyai ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_var(ncfileid,varid_hybi,bk)
  if (ncstatus /= nf90_noerr) then
     print *, 'error writing hybi ',trim(nf90_strerror(ncstatus))
     stop
  endif

  dimid_3d(1) = dimid_lon
  dimid_3d(2) = dimid_lat
  dimid_3d(3) = dimid_lev

  ! if DONT_USE_DPRES env var set, infer the dpres
  ! increment from the ps increment even if dpres exists.
  call getenv('DONT_USE_DPRES',charnin)
  if (charnin .eq. '') then
     has_dpres = has_var(dset_fg,'dpres')
  else
     has_dpres = .false.
  endif
  ! if DONT_USE_DELZ env var set, infer the delz
  ! increment from the ps,Tv increment even if delz exists.
  call getenv('DONT_USE_DELZ',charnin)
  if (charnin .eq. '') then
     has_delz  = has_var(dset_fg,'delz')
  else
     has_delz = .false.
  endif
  print *,'has_dpres ',has_dpres
  print *,'has_delz ',has_delz

  ! ps increment.
  allocate(values_2d_inc(nlons,nlats))
  allocate(taper_vert(nlons,nlats,nlevs))
  allocate(values_3d_inc(nlons,nlats,nlevs))
  do nvar=1,dset_fg%nvars
     ndims = dset_fg%variables(nvar)%ndims
     if (trim(dset_fg%variables(nvar)%name) == 'pressfc') then
        call read_vardata(dset_fg,trim(dset_fg%variables(nvar)%name),values_2d_fg)
        call read_vardata(dset_anal,trim(dset_fg%variables(nvar)%name),values_2d_anal)
        ! increment (flip lats)
        values_2d_inc(:,nlats:1:-1) = values_2d_anal - values_2d_fg
     endif
  enddo
  ! taper function for humidity, ice and liq water increments.
  taper_vert=1.
  if (taper_strat) then
     do k=1,nlevs
        if (k < nlevs/2 .and. (ak(k) <= ak_bot .and. ak(k) >= ak_top)) then
           taper_vert(:,:,k)= (ak(k) - ak_top)/(ak_bot - ak_top)
        else if (bk(k) .eq. 0. .and. ak(k) < ak_top) then
           taper_vert(:,:,k) = 0.
        endif
     enddo
  endif
  if (taper_pbl) then
     do k=1,nlevs
        if (bk(k) >= bk_top) then
           taper_vert(:,:,k)= 1.-(bk(k) - bk_top)/(1.0 - bk_top)
        endif
     enddo
  endif
  if (taper_strat .or. taper_pbl) then
     print *,'profile to taper increments (k,ak,bk,taper):'
     do k=1,nlevs
        print *,k,ak(k),bk(k),taper_vert(1,1,k)
     enddo
  endif

  do nvar=1,dset_fg%nvars
     ndims = dset_fg%variables(nvar)%ndims
     if (ndims == 4) then ! all 3d vars
        ncvarname = 'none'
        !print *,trim(dset_fg%variables(nvar)%name)
        if (trim(dset_fg%variables(nvar)%name) == 'ugrd') then
           ncvarname = 'u_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'vgrd') then
           ncvarname = 'v_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'tmp') then
           ncvarname = 'T_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'dpres' .and. &
                 has_dpres) then
           ncvarname = 'delp_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'spfh') then
           ncvarname = 'sphum_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'o3mr') then
           ncvarname = 'o3mr_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'delz' .and. &
                .not. no_delzinc .and. has_delz) then
           ncvarname = 'delz_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'clwmr' .and. &
                 .not. no_mpinc) then
           ncvarname = 'liq_wat_inc'
        else if (trim(dset_fg%variables(nvar)%name) == 'icmr' .and. &
                 .not. no_mpinc) then
           ncvarname = 'ice_wat_inc'
        endif
        if (trim(ncvarname) /= 'none') then
           print *,'reading ',trim(adjustl(dset_fg%variables(nvar)%name))
           call read_vardata(dset_fg,trim(dset_fg%variables(nvar)%name),values_3d_fg)
           call read_vardata(dset_anal,trim(dset_fg%variables(nvar)%name),values_3d_anal)
           ! increment (flip lats)
           if (taper_strat .and. (trim(ncvarname) .eq. 'sphum_inc' .or. &
                                  trim(ncvarname) .eq. 'liq_wat_inc' .or. &
                                  trim(ncvarname) .eq. 'ice_wat_inc')) then
               values_3d_inc(:,nlats:1:-1,:) = taper_vert*(values_3d_anal - values_3d_fg)
           else
               values_3d_inc(:,nlats:1:-1,:) = values_3d_anal - values_3d_fg
           endif 
           values_3d_inc = forcing_factor*values_3d_inc
           call write_ncdata3d(values_3d_inc,ncvarname,nlons,nlats,nlevs,ncfileid,dimid_3d)
           call compute_stats(values_3d_inc,ncvarname,latwts,inv_sumwt,nlons,nlats,nlevs,fid)
        endif
     endif ! ndims == 4
  enddo  ! nvars
  ! infer delp increment from ps increment
  if (.not. has_dpres) then
     print *,'inferring delp_inc from ps inc'
     ncvarname = 'delp_inc'
     ! ak,bk go from top to bottom, so bk(k+1)-bk(k) > 0
     do k=1,nlevs
        values_3d_inc(:,:,k) = values_2d_inc*(bk(k+1)-bk(k))
     enddo
     values_3d_inc = forcing_factor*values_3d_inc
     call write_ncdata3d(values_3d_inc,ncvarname,nlons,nlats,nlevs,ncfileid,dimid_3d)
     call compute_stats(values_3d_inc,ncvarname,latwts,inv_sumwt,nlons,nlats,nlevs,fid)
  endif
  ! infer delz increment from background, analysis ps & Tv
  if (.not. has_delz .and. .not. no_delzinc) then
     print *,'inferring delz_inc from anal and background ps & Tv'
     ncvarname = 'delz_inc'
     call read_vardata(dset_fg,'tmp',tmp_fg)
     call read_vardata(dset_anal,'tmp',tmp_anal)
     call read_vardata(dset_fg,'spfh',q_fg)
     call read_vardata(dset_anal,'spfh',q_anal)
     call read_vardata(dset_fg,'pressfc',ps_fg)
     call read_vardata(dset_anal,'pressfc',ps_anal)
     tmp_fg = tmp_fg * ( 1.0 + fv*q_fg ) ! convert T to Tv
     tmp_anal = tmp_anal * ( 1.0 + fv*q_anal ) 
     allocate(delzb(nlons,nlats,nlevs))
     allocate(delza(nlons,nlats,nlevs))
     delzb = (rd/grav)*tmp_fg
     delza = (rd/grav)*tmp_anal
     do k=1,nlevs
        delzb(:,:,k)=delzb(:,:,k)*log((ak(k)+bk(k)*ps_fg)/(ak(k+1)+bk(k+1)*ps_fg))
        delza(:,:,k)=delza(:,:,k)*log((ak(k)+bk(k)*ps_anal)/(ak(k+1)+bk(k+1)*ps_anal))
        !print *,k,minval(delzb(:,:,k)),maxval(delzb(:,:,k)),bk(k),bk(k+1)-bk(k)
     enddo
     !print *,'min/max anal delz',minval(delza),maxval(delza)
     !print *,'min/max fg delz',minval(delzb),maxval(delzb)
     values_3d_inc(:,nlats:1:-1,:) = delza - delzb
     values_3d_inc = forcing_factor*values_3d_inc
     call write_ncdata3d(values_3d_inc,ncvarname,nlons,nlats,nlevs,ncfileid,dimid_3d)
     call compute_stats(values_3d_inc,ncvarname,latwts,inv_sumwt,nlons,nlats,nlevs,fid)
  endif

  ncstatus = nf90_close(ncfileid)
  if (ncstatus /= nf90_noerr) then
     print *, 'error closing file:',trim(nf90_strerror(ncstatus))
     stop
  endif
  call close_dataset(dset_fg)
  call close_dataset(dset_anal)
  close(fid)

END PROGRAM calc_increment_ncio

subroutine write_ncdata3d(incdata,ncvarname,&
                          nlons,nlats,nlevs,ncfileid,dimid_3d)
  use netcdf
  implicit none
  integer, intent(in) :: nlons,nlats,nlevs,ncfileid,dimid_3d(3)
  integer varid,ncstatus,trop
  real, intent(in) ::  incdata(nlons,nlats,nlevs)
  character(len=nf90_max_name), intent(in) :: ncvarname
  real :: inv_npts
  if (nlevs > 100) then ! kluge for getting level for around 100 hPa
     trop=52
  else
     trop=42
  endif
  inv_npts=1.0/((nlevs-trop+1)*nlevs*nlats)
  ncstatus = nf90_redef(ncfileid)
  if (ncstatus /= nf90_noerr) then
     print *,'redef error ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_def_var(ncfileid,trim(ncvarname),nf90_float,dimid_3d,varid)
  if (ncstatus /= nf90_noerr) then
     print *, 'error creating ',trim(ncvarname),' ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ! turn on compression (level 1)
  ncstatus = nf90_def_var_deflate(ncfileid, varid, 1,1,1)
  if (ncstatus /= nf90_noerr) then
     print *,'nc_def_var_deflate error ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_enddef(ncfileid)
  if (ncstatus /= nf90_noerr) then
     print *,'enddef error ',trim(nf90_strerror(ncstatus))
     stop
  endif
  ncstatus = nf90_put_var(ncfileid,varid,incdata)
  if (ncstatus /= nf90_noerr) then
     print *, trim(nf90_strerror(ncstatus))
     stop
  endif
end subroutine write_ncdata3d
subroutine compute_stats(incdata,varname,latwts, inv_sumwt, nlons,nlats,nlevs,fid)
  use netcdf
  implicit none
  integer, intent(in) :: nlons,nlats,nlevs
  integer :: trop,kct,k
  real, intent(in) ::  incdata(nlons,nlats,nlevs)
  real, intent(in) ::  latwts(nlons,nlats)
  real*8, intent(in) :: inv_sumwt
  real*8             :: mn,mse
  character(len=nf90_max_name), intent(in) :: varname
  integer,      intent(in) :: fid
  if (trim(varname).EQ.'o3mr_inc') then
     ! use the full profile
     trop=1
  else
     if (nlevs > 100) then ! kluge for getting level for around 100 hPa
        trop=52
     else
        trop=42
     endif
  endif
! compute area weighted global mean and rms
  mn=0.0
  mse=0.0
  kct=0
  DO k=trop,nlevs
    mn = mn + SUM(incdata(:,:,k)*latwts)*inv_sumwt
    mse = mse + SUM((incdata(:,:,k)**2)*latwts)*inv_sumwt
    kct=kct+1
  ENDDO
  mn=mn/kct
  mse=sqrt(mse/kct)
  if (fid == -1) then
     print*, 'Global stastics below level', trop
     write(*,'(A,A24,2e12.3)')  'Mean, RMS of ',adjustl(varname),real(mn,kind=4),real(mse,kind=4)
  else
   write(fid,'(2A,2(A,e12.3))')  'Mean and RMS of, ',trim(adjustl(varname)),',',real(mn,kind=4),',',real(mse,kind=4)
  endif
end subroutine compute_stats

