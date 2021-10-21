echo "running on $machine using $NODES nodes"

# forecast resolution 
# 1/4 deg
export RES=384  
export RES_INC=384
export OCNRES=mx025
# 1-deg
#export RES=96   
#export OCNRES=mx100

#export skip_calc_increment='true'
export exptname=C${RES}cpld_replay_winter
export coupled='ATM_OCN_ICE' # NO or ATM_OCN_ICE
# The SUITE selection has been moved to the bottom of this script
export cores=`expr $NODES \* $corespernode`

export do_cleanup='false' # if true, create tar files, delete *mem* files.
export rungsi="run_gsi_4densvar.sh"
export cleanup_fg='true'
export replay_run_observer='true'
export cleanup_observer='true' 
export resubmit='true'
export save_hpss="true"

# override values from above for debugging.
#export replay_run_observer='false'
#export cleanup_fg='false'
#export resubmit='false'
#export do_cleanup='false'
#export save_hpss="false"
 
if [ "$machine" == 'wcoss' ]; then
   export basedir=/gpfs/hps2/esrl/gefsrr/noscrub/${USER}
   export datadir=/gpfs/hps2/ptmp/${USER}
   export hsidir="/3year/NCEPDEV/GEFSRR/${USER}/${exptname}"
   export obs_datapath=${basedir}/gdas1bufr
elif [ "$machine" == 'theia' ]; then
   export basedir=/scratch3/BMC/gsienkf/${USER}
   export datadir=$basedir
   export hsidir="/ESRL/BMC/gsienkf/2year/Philip.Pegion/${exptname}"
   export obs_datapath=/scratch4/NCEPDEV/global/noscrub/dump
elif [ "$machine" == 'hera' ]; then
   export basedir=/scratch2/BMC/gsienkf/${USER}
   export datadir=$basedir
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   export obs_datapath=/scratch2/BMC/gsienkf/whitaker/gdas1bufr
   source $MODULESHOME/init/sh
   module purge
   module use /scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/modulefiles/stack
   module load hpc/1.1.0
   module load hpc-intel/18.0.5.274
   module load hpc-impi/2018.0.4
   module load hdf5/1.10.6
   module load netcdf/4.7.4
   module load pio/2.5.2
   module load esmf/8_1_1
   module load fms/2020.04.03
elif [ "$machine" == 'gaea' ]; then
   export basedir=/lustre/f2/dev/${USER}
   export datadir=/lustre/f2/scratch/${USER}
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   #export hsidir="/3year/NCEPDEV/GEFSRR/${exptname}"
   export obs_datapath=/lustre/f2/dev/Jeffrey.S.Whitaker/fv3_reanl/gdas1bufr
   source /lustre/f2/pdata/esrl/gsd/contrib/lua-5.1.4.9/init/init_lmod.sh
   #source $MODULESHOME/init/sh
   module load PrgEnv-intel/6.0.5
   module rm intel
   module rm cray-mpich
   module rm netcdf
   module load intel/18.0.6.288
   module load cray-mpich/7.7.11
   module load cray-python/3.7.3.2
   # Needed at runtime:
   module load alps
   module use /lustre/f2/pdata/ncep_shared/cmake-3.20.1/modulefiles
   module load cmake/3.20.1
   module use /lustre/f2/pdata/esrl/gsd/ufs/hpc-stack-v1.1.0/modulefiles/stack
   module load hpc/1.1.0
   module load hpc-intel/18.0.6.288
   module load hpc-cray-mpich/7.7.11
   module load prod_util/1.2.2
   module load bufr/11.4.0
   module load ip/3.3.3
   module load nemsio/2.5.2
   module load sfcio/1.4.1
   module load sigio/2.3.2
   module load sp/2.3.3
   module load w3nco/2.4.1
   module load w3emc/2.7.3
   module load bacio/2.4.1
   module load crtm/2.3.0
   module load netcdf/4.7.4
   module load wgrib
elif [ "$machine" == 'cori' ]; then
   export basedir=${SCRATCH}
   export datadir=$basedir
   export hsidir="fv3_reanl/${exptname}"
   export obs_datapath=${basedir}/gdas1bufr
else
   echo "machine must be 'wcoss', 'theia', 'gaea' or 'cori', got $machine"
   exit 1
fi
export datapath="${datadir}/${exptname}"
export logdir="${datadir}/logs/${exptname}"

# directory with bias correction files for GSI
# comment this out and 3DVar will be run to generate bias coeffs
export biascorrdir=${basedir}/biascor

# directory with analysis netcdf files
#export replayanaldir=/scratch2/NCEPDEV/stmp1/Jeffrey.S.Whitaker/C192ifsanal
#export analfileprefix="C192_ifsanl"
export replayanaldir=${basedir}/era5anl/C${RES}
export replayanaldir_lores=${basedir}/era5anl/C${RES_INC}
export ocnanaldir=${basedir}/oras5/${OCNRES}
export analfileprefix="C${RES}_era5anl"
export analfileprefix_lores="C${RES_INC}_era5anl"

export ifsanal="false"  # true if using IFS analysis from original files, false if using pre-processed UFS or IFS analysis

export NOSAT="YES" # if yes, no radiances assimilated
export NOCONV="NO"
#  nst_gsi  - indicator to control the Tr Analysis mode: 0 = no nst info in gsi at all;
#                                                        1 = input nst info, but used for monitoring only
#                                                        2 = input nst info, and used in CRTM simulation, but no Tr analysis
#                                                        3 = input nst info, and used in CRTM simulation and Tr analysis is on
export NST_GSI=0          # No NST in GSI
#export NST_GSI=2          # passive NST
export LSOIL=4
#export LSOIL=9 #RUC LSM
export FHCYC=6
if [ $FHCYC -gt 0 ]; then
    export skip_global_cycle='YES'
fi

# resolution dependent model parameters
if [ $RES -eq 384 ];then
   export LONB=1536 
   export LATB=768  
   export JCAP=766   
fi
if [ $RES -eq 96 ];then
   export JCAP=188 
   export LONB=384   
   export LATB=192  
fi
if [ $RES_INC -eq 96 ];then
   export LONB_INC=384   
   export LATB_INC=192  
fi
if [ $RES -eq 768 ]; then
   export dt_atmos=120
   export cdmbgwd_ctl="4.0,0.15,1.0,1.0"
elif [ $RES -eq 384 ]; then
   export dt_atmos=225
   #export dt_atmos=180
   export cdmbgwd="1.1,0.72,1.0,1.0"
elif [ $RES -eq 192 ]; then
   export dt_atmos=450
   export cdmbgwd="0.23,1.5,1.0,1.0"
elif [ $RES -eq 96 ]; then
   export dt_atmos=900
   #export dt_atmos=450
   export cdmbgwd="0.14,1.8,1.0,1.0"  # mountain blocking, ogwd, cgwd, cgwd src scaling
else
   echo "model time step for ensemble resolution C$RES not set"
   exit 1
fi
if [ "$OCNRES" == 'mx100' ]; then
   export dt_ocn=3600
   export ORES3='100'
elif [ "$OCNRES" == 'mx025' ]; then
   export dt_ocn=1800
   export ORES3='025'
else
   echo "$OCNRES is not supported, plesae try mx100 or mx025"
   exit 1
fi

export LONA=$LONB
export LATA=$LATB      
export ANALINC=6
export LEVS=127
export FHMIN=0
export FHMAX=9
export FHOUT=3
export RESTART_FREQ=3
#export FHRESTART="0 3" # default is "$RESTART_FREQ,1"
export FRAC_GRID=T
export iaufhrs="6"
export iau_delthrs="6" # iau_delthrs < 0 turns IAU off

export perturbed_replay="NO"
export nmem=0
#export perturbed_replay="YES"
#export nmem=2 # perturbed member (gets added to random seeds)
if [ $perturbed_replay == "YES" ]; then
    nmemm1=$((nmem01))
    export analfileprefix="C${RES}_era5anl_${nmemm1}"
    export iau_forcing_factor_atm=100  
    export iau_forcing_factor_ocn=100  
    # these go in  nam_stochy block of atmospheric model input.nml
    export DO_SPPT=.true.
    export PERT_MP=.true.
    export PERT_CLDS=.true.
    export SPPT=0.5
    export DO_SHUM=.true.
    export SHUM=0.005
    export DO_SKEB=.true.
    export SKEB=0.3
    export OCNSPPT=0.8
    export OCNSPPT_TAU=21600
    export OCNSPPT_LSCALE=500000
    export EPBL=0.8
    export EPBL_TAU=21600
    export EPBL_LSCALE=500000
    # tese go in MOM_input
    export DO_OCNSPPT=True
    export DO_PERT_EPBL=True
else
    export iau_forcing_factor_atm=100  
    export iau_forcing_factor_ocn=100  
    # these go in  nam_stochy block of atmospheric model input.nml
    export SKEB=0
    export DO_SKEB=.false.
    export SPPT=0
    export DO_SPPT=.false.
    export PERT_MP=.false.
    export PERT_CLDS=.false.
    export SHUM=0
    export DO_SHUM=.false.
    export OCNSPPT=0.
    export OCNSPPT_TAU=21600
    export OCNSPPT_LSCALE=500000
    export EPBL=0.
    export EPBL_TAU=21600
    export EPBL_LSCALE=500000
    # tese go in MOM_input
    export DO_OCNSPPT=False
    export DO_PERT_EPBL=False
fi

# other model variables set in ${rungfs}
# other gsi variables set in ${rungsi}

export RUN=gdas # use gdas obs

export nitermax=1

export scriptsdir="${basedir}/scripts/${exptname}"
export homedir=$scriptsdir
export incdate="${scriptsdir}/incdate.sh"

if [ "$coupled" == 'NO' ];then
   export fv3exec='fv3-nonhydro.exe'
else
   export fv3exec='ufs_coupled.exe'
fi

if [ "$machine" == 'hera' ]; then
   export FIXDIR=/scratch2/BMC/gsienkf/whitaker/P7fix
   export FIXcice=$FIXDIR/fix_cice/${ORES3}
   export FIXmom=$FIXDIR/fix_mom6/${ORES3}
   export gsipath=${basedir}/gsi/GSI-github-jswhit-master
   export fixgsi=${gsipath}/fix
   export fixcrtm=/scratch2/NCEPDEV/nwprod/NCEPLIBS/fix/crtm_v2.3.0
   export execdir=${scriptsdir}/exec_${machine}
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
elif [ "$machine" == 'gaea' ]; then
   # copied from /scratch2/NCEPDEV/climate/role.ufscpara/Prototype7.0/global-workflow/fix on 8/31/2021
   export FIXDIR=/lustre/f2/dev/Jeffrey.S.Whitaker/P7fix
   export FIXcice=$FIXDIR/fix_cice/${ORES3}
   export FIXmom=$FIXDIR/fix_mom6/${ORES3}
   export gsipath=/scratch1/NCEPDEV/global/glopara/git/global-workflow/gfsv16b/sorc/gsi.fd
   export gsipath=${basedir}/GSI-github-jswhit
   export fixgsi=${gsipath}/fix
   export fixcrtm=/lustre/f2/pdata/ncep_shared/NCEPLIBS/lib/crtm/v2.3.0/fix
   export execdir=${scriptsdir}/exec_${machine}
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
else
   echo "${machine} unsupported machine"
   exit 1
fi

export ANAVINFO=${fixgsi}/global_anavinfo.l${LEVS}.txt
export HYBENSINFO=${fixgsi}/global_hybens_info.l${LEVS}.txt
export CONVINFO=$fixgsi/global_convinfo.txt
export OZINFO=$fixgsi/global_ozinfo.txt
export SATINFO=$fixgsi/global_satinfo.txt

# parameters for GSI
export aircraft_bc=.false.
export use_prepb_satwnd=.false.
export imp_physics=11 # used by GSI, not model
if [ $LEVS -eq 64 ]; then
  export nsig_ext=12
  export gpstop=50
  export GRIDOPTS="nlayers(63)=3,nlayers(64)=6,"
elif [ $LEVS -eq 127 ]; then
  export nsig_ext=56
  export gpstop=55
  export GRIDOPTS="nlayers(63)=1,nlayers(64)=1,"
else
  echo "LEVS must be 64 or 127"
  exit 1
fi

# new namelist settings for coupled/not-coupled
if [ "$coupled" == 'NO' ]; then
   export SUITE="FV3_GFS_v16beta_no_nsst"
   export rungfs="run_fv3.sh"
elif [ "$coupled" == 'ATM_OCN_ICE' ]; then
   #export SUITE="FV3_GFS_v16_coupled"
   #export NSTFNAME="0,0,0,0"
   export SUITE="FV3_GFS_v16_coupled_nsstNoahmpUGWPv1"
   export NSTFNAME="2,0,0,0"
   export rungfs="run_coupled.sh"
elif [ "$coupled" == 'ATM_OCN_ICE_WAV' ]; then
   export SUITE="FV3_GFS_v16_coupled"
   #export SUITE=FV3_GFS_v16_coupled_nsstNoahmpUGWPv1
   export rungfs="run_coupled_wav.sh"
   echo "${coupled} option not yet supported"
   echo "please chose betwee NO ATM_OCN_ICE"
   exit 1
else
   echo "${coupled} option not supported"
   echo "please chose betwee NO ATM_OCN_ICE"
   exit 1
fi

cd $scriptsdir
echo "run main driver script"
if [ -z $longfcst ]; then
   echo "running replay cycle `date`..."
   sh -x main.sh
else
   echo "running long fcst for analdate=$analdate `date` .."
   sh run_longfcst.sh
   echo "done running long forecast for analdate=$analdate `date` .."
fi
