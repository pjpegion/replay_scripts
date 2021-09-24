export longfcst=1
#date=2016010218
#while [ $date -le 2016033118 ]; do
while read date; do
   datep6=`incdate $date 6`
   export analdate=$datep6
   sh submit_coupled_job.sh gaea
done < "longfcst_dates.txt"
#  date=`incdate $date 24`
#done
