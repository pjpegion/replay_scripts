
#export fv3gfspath=/scratch4/NCEPDEV/global/save/glopara/svn/fv3gfs
#export FIXFV3=${fv3gfspath}/fix/fix_fv3_gmted2010
#export FIXGLOBAL=${fv3gfspath}/fix/fix_am
#export LEVS=64
#export datapath=/scratch3/BMC/gsienkf/whitaker/C192C192_dualres_oper
#export analdate=2016010106
#export datapath2=${datapath}/${analdate}
export OMP_NUM_THREADS=2
export LONB=512    #C128 grid
export LATB=256  

export LEVSp1=`expr $LEVS \+ 1`
SIGLEVEL=${SIGLEVEL:-${FIXGLOBAL}/global_hyblev.l${LEVSp1}.txt}
export CHGRESEXEC=${execdir}/chgres_recenter.exe

DATA=$datapath2/chgrestmp$$
mkdir -p $DATA
pushd $DATA

#ln -fs ${datapath2}/sanl_${analdate}_fhr06_control       atmanl_gsi
#ln -fs ${datapath2}/sanl_${analdate}_fhr06_ensmean       atmanl_ensmean
ln -fs $1       atmanl_gsi
ln -fs $2       atmanl_ensmean

rm -f fort.43
cat > fort.43 << EOF
&nam_setup
  i_output=$LONB
  j_output=$LATB
  input_file="atmanl_gsi"
  output_file="atmanl_gsi_ensres"
  terrain_file="atmanl_ensmean"
  vcoord_file="$SIGLEVEL"
/
EOF

$CHGRESEXEC

if [ -s atmanl_gsi_ensres ]; then
   mv atmanl_gsi_ensres $3
else
   popd
   /bin/rm -rf $DATA
   exit 1
fi

popd
/bin/rm -rf $DATA
exit 0
