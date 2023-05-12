#!/bin/sh
export machine='aws'
export scriptsdir=$PWD
export datapath=/lustre/role.ca-ufs-rnr/GEFSv13_replay_stream3
export analdate=2004082406
export analdate_prod=2005010100
export exptname=GEFSv13_replay_stream3
sh ./hpss.sh >&archive_${analdate}.out
