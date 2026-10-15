#!/bin/sh
export machine='aws'
export scriptsdir=$PWD
export exptname=GEFSv13_replay_stream7
export datapath=/lustre/role.ca-ufs-rnr/${exptname}
export analdate=1979030406
export analdate_prod=2005010100
sh ./hpss.sh >&archive_${analdate}.out
