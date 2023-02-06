#!/bin/bash --posix

machine='hera'
source $MODULESHOME/init/sh
module purge

/bin/rm -rf ufs-weather-model
git clone https://github.com/ufs-community/ufs-weather-model ufs-weather-model
cd ufs-weather-model
git checkout c22aaadfb8dafb5687e2f3bf6416e8f11e3f9a1d # hash will probably become HR1 tag
git submodule update --init --recursive

# patch to turn off saving of IAU increments in MOM6 restart
patch -p 0 < ../mom6_iau_restart_develop.diff
# patch for skipping MOM6 restart at end
patch -p 0 < ../mom_cap.diff

cd tests
./compile.sh ${machine}.intel "-DAPP=S2SW -D32BIT=ON -DCCPP_SUITES=FV3_GFS_v17_coupled_p8" coupled YES NO
./compile.sh ${machine}.intel "-DAPP=ATM -D32BIT=ON -DCCPP_SUITES=FV3_GFS_v17_p8" atmonly YES NO
cd ../../
/bin/cp -f ufs-weather-model/tests/fv3_coupled.exe ../exec_${machine}/ufs_coupled.exe
/bin/cp -f ufs-weather-model/tests/fv3_atmonly.exe ../exec_${machine}/fv3_atm.exe
/bin/rm -rf ufs-weather-model
