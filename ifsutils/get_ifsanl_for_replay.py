from ecmwfapi import ECMWFService
import datetime, sys
from dateutils import dateshift,splitdate

# date to retrieve
date = sys.argv[1]
dateref = dateshift(date,12) # wait till 12-h after 
if dateref > datetime.datetime.utcnow().strftime('%Y%m%d%H'):
    raise ValueError('data for %s not yet available' % date)
else:
    print "retrieving for %s" % date

# number of vertical levels.
nlevs = 137
levelist = []
for nlev in range(1,nlevs+1):
    levelist.append('%s/' % nlev)
levelist137 = ''.join(levelist)[:-1]

# output grid
#grid = '0.075/0.075' # lat/lon spacing
grid = 'F640' # 1280 latitude gaussian grid

#parameters="phis/lnps/tmp/spfh/ugrd/vgrd/clwmr/icwmr/rnwmr/snwmr/vvel"
#parameters="129/152/130/133/131/132/246/247/75/76/135"
# phis/lnps/tmp/spfh/ugrd/vgrd/o3mr
parameters = "129/152/130/133/131/132/203"

# get data one date at a time, all fields at once.
server = ECMWFService('mars')

yyyy,mm,dd,hh = splitdate(date)
print "requesting fields for %s ...." % date
server.execute({
    'stream'    : "oper",
    'class'     : "od",
    'expver'    : "1",
    'levtype'   : "ml",
    'type'      : "an",
    'param'     : "%s" % parameters, 
    'date'      : "%04i-%02i-%02i" % (yyyy,mm,dd),
    'time'      : "%02i" % hh,
    'levelist'  : "%s" % levelist137,
    'format'    : "netcdf",
    'grid'      : "%s" % grid},
    "IFSANALreplay_ics_%s.nc" % date)
