# replay_scripts
scripts to replay FV3 model to IFS analyses

* config.sh is the main driver script.  It sets parameters (via env variables) and then
  runs main.csh.  It can be submitted via 'sh submit_job.sh <machine_name>'  where
  <machine_name> can be hera, theia, gaea.  Executables for each platform live
  in exec_<machine_name>.  Right now only hera is tested.
  All scripts and executables live in basedir/scripts/exptname (basedir and exptname set in config.sh).
  Data generated from replay cycle lives in basedir/exptname.

* main.csh performs the replay cycle.  This includes
  1)  running the GSI observer to compute the fit of the predictor segment to obs
      (requires bufr data and bias correction data directories specified as obs_datapath
       and biascorrdir in config.sh).  Uses run_gsiobserver.csh which calls
       run_gsi_4densvar.sh.
  2)  Run the corrector segment and the predictor segment for the next cycle (using
      run_fg_control.csh which calls run_fv3.sh).  Model forecast data is written out
      in netcdf files of the form sfg_YYYYYMMDDHH_fhr##_control, where YYYYMMDDHH is the 
      center of the current window (corrector segment), and ## is fhr forecast hour
      relative to YYYYMMDDHH.  These files are written to basedir/exptname/YYYYMMDHHnext, where
      YYYYMMDDHHnext is YYYYMMDDH + 6hours.
      run_fv3.sh runs calc_increment.py, which computes analysis
      increments to force the model using IFS analysis data in ifsanaldir.
  3)  clean.csh removes uneeded files, and hpss.sh backs up remaining data to HPSS in 
      directory specified by hsidir.

Notes:  Requires GSI from 'fv3_ncio' ProdGSI branch.  Requires FV3 from 'nc_time_units_fix' branch.
Also requires global_cycle and nc_diag_cat.x (from GSI).
