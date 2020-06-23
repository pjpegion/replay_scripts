echo "running on $machine using $NODES nodes"

export exptname=gfsv16_ifsreplay_test
export cores=`expr $NODES \* $corespernode`

export do_cleanup='true' # if true, create tar files, delete *mem* files.
export rungfs="run_fv3.sh"
export rungsi="run_gsi_4densvar.sh"
export cleanup_fg='true'
export replay_run_observer='true'
export cleanup_observer='true' 
export resubmit='true'
export save_hpss="true"
export do_cleanup='true'

# override values from above for debugging.
#export cleanup_observer="false"
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
   export obs_datapath=/scratch1/NCEPDEV/global/glopara/dump
   source $MODULESHOME/init/sh
   module purge
   module load intel/18.0.5.274
   module load impi/2018.0.4 
   module use -a /scratch1/NCEPDEV/nems/emc.nemspara/soft/modulefiles
   module load hdf5_parallel/1.10.6
   module load netcdf_parallel/4.7.4
   module load esmf/8.0.0_ParallelNetCDF
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
export ifsanldir=/scratch2/NCEPDEV/stmp1/Jeffrey.S.Whitaker/ecanl

# forecast resolution 
export RES=768  

export NOSAT="NO" # if yes, no radiances assimilated
export NOCONV="NO"
#  nst_gsi  - indicator to control the Tr Analysis mode: 0 = no nst info in gsi at all;
#                                                        1 = input nst info, but used for monitoring only
#                                                        2 = input nst info, and used in CRTM simulation, but no Tr analysis
#                                                        3 = input nst info, and used in CRTM simulation and Tr analysis is on
export NST_GSI=0          # No NST in GSI
#export NST_GSI=2          # passive NST
export SUITE="FV3_GFS_v16beta_no_nsst"
export LSOIL=4 
#export LSOIL=4  # for RUC LSM, doesn't work with global_cycle

# resolution dependent model parameters
export LONB=2560
export LATB=1280
export JCAP=1278
if [ $RES -eq 768 ]; then
   export dt_atmos=150
elif [ $RES -eq 384 ]; then
   export dt_atmos=225
elif [ $RES -eq 192 ]; then
   export dt_atmos=450
elif [ $RES -eq 128 ]; then
   export dt_atmos=720
elif [ $RES -eq 96 ]; then
   export dt_atmos=900
else
   echo "model time step for ensemble resolution C$RES_CTL not set"
   exit 1
fi

export LONA=$LONB
export LATA=$LATB      
export ANALINC=6
export LEVS=127
export FHMIN=3
export FHMAX=9
export FHOUT=3
export FHCYC=0
export iaufhrs="6"
export iau_delthrs="6" # iau_delthrs < 0 turns IAU off

# other model variables set in ${rungfs}
# other gsi variables set in ${rungsi}

export RUN=gdas # use gdas obs

export nitermax=1

export scriptsdir="${basedir}/scripts/${exptname}"
export homedir=$scriptsdir
export incdate="${scriptsdir}/incdate.sh"

export fv3exec='fv3-nonhydro.exe'

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
elif [ "$machine" == 'hera' ]; then
   export fv3gfspath=/scratch1/NCEPDEV/global/glopara
   export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
   export FIXGLOBAL=${fv3gfspath}/fix/fix_am
   export gsipath=/scratch2/BMC/gsienkf/whitaker/gsi/ProdGSI
   export fixgsi=${gsipath}/fix
   export fixcrtm=/scratch1/NCEPDEV/global/glopara/crtm/v2.2.6/fix
   export execdir=${scriptsdir}/exec_${machine}
   export FCSTEXEC=${execdir}/${fv3exec}
   export gsiexec=${execdir}/global_gsi
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
else
   echo "${machine} unsupported machine"
   exit 1
fi

export ANAVINFO=${fixgsi}/global_anavinfo.l127.txt
export HYBENSINFO=${fixgsi}/global_hybens_info.l127.txt
export CONVINFO=/scratch1/NCEPDEV/global/glopara/git/global-workflow/gfsv16b_retro2d/fix/fix_gsi/gfsv16_historical/global_convinfo.txt.2019021900
export OZINFO=/scratch1/NCEPDEV/global/glopara/git/global-workflow/gfsv16b_retro2d/fix/fix_gsi/global_ozinfo.txt
export SATINFO=/scratch1/NCEPDEV/global/glopara/git/global-workflow/gfsv16b_retro2d/fix/fix_gsi/global_satinfo.txt

# parameters for GSI
export aircraft_bc=.true.
export use_prepb_satwnd=.false.

cd $scriptsdir
echo "run main driver script"
csh main.csh
