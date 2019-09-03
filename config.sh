echo "running on $machine using $NODES nodes"
## ulimit -s unlimited

export exptname=C768_ifs_replay
export cores=`expr $NODES \* $corespernode`

export do_cleanup='true' # if true, create tar files, delete *mem* files.
export rungfs="run_fv3.sh"
export rungsi="run_gsi_4densvar.sh"
export cleanup_fg='true'
export replay_run_observer='true'
export cleanup_observer='true' 
export cleanup_nemsio2nc='true'
export resubmit='true'
export save_hpss="false"
export do_cleanup='true'

# override values from above for debugging.
#export cleanup_observer="false"
#export cleanup_nemsio2nc="false"
#export cleanup_fg='false'
#export resubmit='false'
#export do_cleanup='false'
 
if [ "$machine" == 'wcoss' ]; then
   export basedir=/gpfs/hps2/esrl/gefsrr/noscrub/${USER}
   export datadir=/gpfs/hps2/ptmp/${USER}
   export hsidir="/3year/NCEPDEV/GEFSRR/${USER}/${exptname}"
   export obs_datapath=${basedir}/gdas1bufr
elif [ "$machine" == 'theia' ]; then
   export basedir=/scratch3/BMC/gsienkf/${USER}
   export datadir=$basedir
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   export obs_datapath=/scratch4/NCEPDEV/global/noscrub/dump
elif [ "$machine" == 'hera' ]; then
   export basedir=/scratch2/BMC/gsienkf/${USER}
   export datadir=$basedir
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   #export obs_datapath=/scratch2/NCEPDEV/global/noscrub/dump
   export obs_datapath=/scratch4/NCEPDEV/global/noscrub/dump
elif [ "$machine" == 'gaea' ]; then
   export basedir=/lustre/f1/unswept/${USER}
   export datadir=/lustre/f1/${USER}
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   #export hsidir="/3year/NCEPDEV/GEFSRR/${exptname}"
   export obs_datapath=/lustre/f1/unswept/Jeffrey.S.Whitaker/fv3_reanl/gdas1bufr
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
export biascorrdir=${datadir}/biascor
# directory with IFS analysis netcdf files
export ifsanldir=/scratch3/NCEPDEV/stmp1/Jeffrey.S.Whitaker/ecanl

# forecast resolution 
export RES=768  

# model physics parameters.
export psautco="0.0008,0.0005"
export prautco="0.00015,0.00015"
#export imp_physics=99 # zhao-carr
export imp_physics=11 # GFDL MP

export NOSAT="NO" # if yes, no radiances assimilated
export NOCONV="NO"
# model NSST parameters contained within nstf_name in FV3 namelist
# (comment out to get default - no NSST)
# nstf_name(1) : NST_MODEL (NSST Model) : 0 = OFF, 1 = ON but uncoupled, 2 = ON and coupled
#export DONST="YES"
#export NST_MODEL=2
## nstf_name(2) : NST_SPINUP : 0 = OFF, 1 = ON,
#export NST_SPINUP=0 # (will be set to 1 if fg_only=='true')
## nstf_name(3) : NST_RESV (Reserved, NSST Analysis) : 0 = OFF, 1 = ON
#export NST_RESV=0
## nstf_name(4,5) : ZSEA1, ZSEA2 the two depths to apply vertical average (bias correction)
#export ZSEA1=0
#export ZSEA2=0
#export NSTINFO=0          # number of elements added in obs. data array (default = 0)
#export NST_GSI=3          # default 0: No NST info at all;
                          #         1: Input NST info but not used in GSI;
                          #         2: Input NST info, used in CRTM simulation, no Tr analysis
                          #         3: Input NST info, used in both CRTM simulation and Tr analysis

export NST_GSI=0          # No NST 

if [ $NST_GSI -gt 0 ]; then export NSTINFO=4; fi
if [ $NOSAT == "YES" ]; then export NST_GSI=0; fi # don't try to do NST in GSI without satellite data

if [ $imp_physics == "11" ]; then
   export ncld=5
   export nwat=6
   export cal_pre=F
   export dnats=1
   export do_sat_adj=".true."
   export random_clds=".false."
   export cnvcld=".false."
   export lgfdlmprad=".true."
   export effr_in=".true."
else
   export ncld=1
   export nwat=2
   export cal_pre=T
   export dnats=0
fi
export k_split=1
export n_split=6
export fv_sg_adj=450
export hydrostatic='F'
if [ $hydrostatic == 'T' ];  then
   export fv3exec='fv3-hydro.exe'
   export consv_te=0
else
   export fv3exec='fv3-nonhydro.exe'
   export consv_te=1
fi
# defaults in exglobal_fcst
if [ $hydrostatic == 'T' ];  then
   export fv3exec='fv3-hydro.exe'
   export hord_mt=10
   export hord_vt=10
   export hord_tm=10
   export hord_dp=-10
   export vtdm4=0.05
   export consv_te=0
else
   export fv3exec='fv3-nonhydro.exe'
   export hord_mt=5
   export hord_vt=5
   export hord_tm=5
   export hord_dp=-5
   export vtdm4=0.06
   export consv_te=1
fi
# GFDL suggests this for imp_physics=11
#if [ $imp_physics -eq 11 ]; then 
#   export hord_mt=6
#   export hord_vt=6
#   export hord_tm=6
#   export hord_dp=-6
#   export nord=2
#   export dddmp=0.1
#   export d4_bg=0.12
#   export vtdm4=0.02
#fi

# stochastic physics parameters.
export SPPT=0.0
export SPPT_TSCALE=21600.
export SPPT_LSCALE=500.e3
export SHUM=0.0
export SHUM_TSCALE=21600.
export SHUM_LSCALE=500.e3
export SKEB=0.0
export SKEB_TSCALE=21600.
export SKEB_LSCALE=500.e3
export SKEBNORM=0
export SKEB_NPASS=30
export SKEB_VDOF=5
export RNDA=0.0
export RNDA_VDOF=0
export RNDA_LSCALE=250.
export RNDA_TSCALE=21600.
export RNDA_PERTVORTFLUX=T

# resolution dependent model parameters
if [ $RES -eq 768 ]; then
   export cdmbgwd="3.5,0.25"
   export LONB=2560
   export LATB=1280
   export k_split=2
   export n_split=6
   export dt_atmos=225
   export JCAP=1278
elif [ $RES -eq 384 ]; then
   export JCAP=1278
   export LONB=2560
   export LATB=1280
   export dt_atmos=225
   export cdmbgwd="1.0,1.2"
elif [ $RES -eq 192 ]; then
   export JCAP=382 
   export LONB=800   
   export LATB=400  
   export dt_atmos=450
   export cdmbgwd="0.2,2.5"
elif [ $RES -eq 128 ]; then
   export JCAP=254 
   export LONB=512   
   export LATB=256  
   export dt_atmos=720
   export cdmbgwd="0.15,2.75"
elif [ $RES -eq 96 ]; then
   export JCAP=188 
   export LONB=400   
   export LATB=200  
   export dt_atmos=900
   export cdmbgwd="0.125,3.0"
else
   echo "model parameters for ensemble resolution C$RES_CTL not set"
   exit 1
fi

export LONA=$LONB
export LATA=$LATB      
export ANALINC=6
export LEVS=64
export FHMIN=3
export FHMAX=9
export FHOUT=3
export FHCYC=0
#export iaufhrs="3,6,9"
export iaufhrs="6"
export iau_delthrs="6" # iau_delthrs < 0 turns IAU off

# other model variables set in ${rungfs}
# other gsi variables set in ${rungsi}

export RUN=gdas # use gdas obs

export nitermax=1

export scriptsdir="${basedir}/scripts/${exptname}"
export homedir=$scriptsdir
export incdate="${scriptsdir}/incdate.sh"

if [ "$machine" == 'theia' ]; then
   export fv3gfspath=/scratch4/NCEPDEV/global/save/glopara/svn/fv3gfs
   export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export gsipath=/scratch3/BMC/gsienkf/whitaker/gsi/ProdGSI
   export fixgsi=${gsipath}/fix
   export fixcrtm=/scratch3/BMC/gsienkf/whitaker/gsi/branches/EXP-enkflinhx/fix/crtm_2.2.3
   export execdir=${scriptsdir}/exec_${machine}
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
elif [ "$machine" == 'hera' ]; then
   export fv3gfspath=/scratch1/NCEPDEV/global/glopara
   export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export gsipath=/scratch2/BMC/gsienkf/whitaker/gsi/ProdGSI
   export fixgsi=${gsipath}/fix
   #export fixcrtm=/scratch3/BMC/gsienkf/whitaker/gsi/branches/EXP-enkflinhx/fix/crtm_2.2.3
   export fixcrtm=/scratch1/NCEPDEV/global/gwv/l827h/lib/crtm/v2.2.6/fix
   export execdir=${scriptsdir}/exec_${machine}
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
elif [ "$machine" == 'gaea' ]; then
# warning - these paths need to be updated on gaea
   export fv3gfspath=/lustre/f1/unswept/Jeffrey.S.Whitaker/fv3_reanl/fv3gfs/global_shared.v15.0.0
## export fv3gfspath=${basedir}/fv3gfs/global_shared.v15.0.0
   export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export gsipath=/lustre/f1/unswept/Jeffrey.S.Whitaker/fv3_reanl/ProdGSI
## export gsipath=${basedir}/ProdGSI
   export fixgsi=${gsipath}/fix
   export fixcrtm=${fixgsi}/crtm_v2.2.3
   export execdir=${scriptsdir}/exec_${machine}
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
elif [ "$machine" == 'wcoss' ]; then
   export fv3gfspath=/gpfs/hps3/emc/global/noscrub/emc.glopara/svn/fv3gfs
   export gsipath=/gpfs/hps2/esrl/gefsrr/noscrub/Jeffrey.S.Whitaker/gsi/ProdGSI
   export FIXFV3=${fv3gfspath}/fix_fv3
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export fixgsi=${gsipath}/fix
   export fixcrtm=${fixgsi}/crtm_v2.2.3
   export execdir=${scriptsdir}/exec_${machine}
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
   export nemsioget=${execdir}/nemsio_get
else
   echo "${machine} unsupported machine"
   exit 1
fi

export ANAVINFO=${scriptsdir}/global_anavinfo.l64.txt
export HYBENSINFO=${scriptsdir}/global_hybens_info.l64.txt
export CONVINFO=${scriptsdir}/global_convinfo.txt.2009111900
export OZINFO=${scriptsdir}/global_ozinfo.txt.2013010100
export SATINFO=${scriptsdir}/global_satinfo.txt

# parameters for hybrid
export beta1_inv=1.0    # 0 means all ensemble, 1 means all 3DVar.
export s_ens_h=485      # a gaussian e-folding, similar to sqrt(0.15) times Gaspari-Cohn length
export s_ens_v=-0.582   # in lnp units.
export aircraft_bc=.true.
export use_prepb_satwnd=.false.

cd $scriptsdir
echo "run main driver script"
csh main.csh
