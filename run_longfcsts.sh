export longfcst=1
date=2016010218
while [ $date -le 2016033118 ]; do
   export analdate=$date
   sh submit_coupled_job.sh gaea
   date=`incdate $date 24`
done
