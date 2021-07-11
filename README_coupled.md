# replay_scripts
scripts to replay FV3 model to ERA-5 and ORAS5 analyses

* config.sh is the main driver script.  It sets parameters (via env variables) and then
  runs main.sh.  It can be submitted via 'sh submit_coupled_job.sh <machine_name>'  where
  <machine_name> must be hera.  Executables for each platform live
  in exec_<machine_name>.  Right now only hera is tested.
  All scripts and executables live in basedir/scripts/exptname (basedir and exptname set in config.sh).
  Data generated from replay cycle lives in basedir/exptname.

* the physics suite is specified via the SUITE env in config.sh. ${SUITE}.nml, ${SUITE}.field_table
  must exist in this (the scripts) directory.

* main.sh performs the replay cycle.  This includes
  1)  running the GSI observer to compute the fit of the predictor segment to obs
      (requires bufr data and bias correction data directories specified as obs_datapath
       and biascorrdir in config.sh).  Uses run_gsiobserver.sh which calls
       run_gsi_4densvar.sh.
  2)  Run the corrector segment and the predictor segment for the next cycle (using
      run_fg_control.sh which calls run_fv3.sh).  Model forecast data is written out
      in netcdf files of the form sfg_YYYYYMMDDHH_fhr##_control, where YYYYMMDDHH is the 
      center of the current window (corrector segment), and ## is fhr forecast hour
      relative to YYYYMMDDHH.  These files are written to basedir/exptname/YYYYMMDHHnext, where
      YYYYMMDDHHnext is YYYYMMDDH + 6hours.
      run_fv3.sh runs calc_increment.py, which computes analysis
      increments to force the model using IFS analysis data in ifsanaldir.
  3)  clean.sh removes uneeded files, and hpss.sh backs up remaining data to HPSS in 
      directory specified by hsidir.


Setting up a new run:
   1) create an experiement directory, which is $datadir/$exptname in config.sh
   2) populate analdate.sh and fg_only.sh files
      example for a cold start on Dec 1 2015:
       > cat analdate.txt
         export analdate=2015120100
         export analdate_end=2016010100
       > cat fg_only.sh
         export fg_only=true
         export cold_start=true 
    3) cd to experiement directory and 
       > mkdir 2015120100
       > cd 2015120100
       > mkdir INPUT
    4) link in ice initial condition to this directory
       #0.25deg
       > ln -sf /scratch2/NCEPDEV/climate/climpara/S2S/IC/CPC/2015120100/ice/025/cice5_model_0.25.res_2015120100.nc .
       #1-deg
       > ln -sf /scratch2/BMC/gsienkf/Philip.Pegion/UFS-coupled/ICS/mx100/2015120100/cice5_model_1.00.ic.nc .
    5) copy ocean initial conditions into INPUT directoy
      > cd INPUT
      # 0.25deg
      > ln -sf ln -sf /scratch2/BMC/gsienkf/Philip.Pegion/UFS-coupled/ICS/mx025/20151201/ORAS5.mx025.ic.nc .
      # 1-deg
      > ln -sf /scratch2/BMC/gsienkf/Philip.Pegion/UFS-coupled/ICS/mx100/20151201/ORAS5.mx100.ic.nc .

    6) link in atmosphere initial conditions
      # C384
     ln -sf /scratch2/NCEPDEV/climate/climpara/S2S/IC/CFSRfracL127/2015120100/gfs/C384/INPUT/* .
      # C96 ???
      
     Note if running 1-degree, you will need to modify the calc_ocean_increments_from_ORAS5.F90 to point to the mx100 data and compile with compile_calc_ocn_inc.sh

Notes:  Requires global_cycle and nc_diag_cat.x (executables in exec_<machine> directory)
