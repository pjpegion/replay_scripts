set date=2016010106
while ($date <= 201601011800) 
  echo "increment for $date"
  python calc_increment.py /scratch3/BMC/gsienkf/Jeffrey.S.Whitaker/C384_replay_control/${date}/sfg_${date}_fhr06_control.nc4 /scratch3/BMC/gsienkf/whitaker/ifsanl/ifsanl_C384_F384_${date}.nc test_inc.nc
  set date=`incdate $date 6`
end
