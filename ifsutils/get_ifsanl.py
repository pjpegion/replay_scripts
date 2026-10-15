from ecmwfapi import ECMWFService
import datetime

def splitdate(yyyymmddhh):
    """
 yyyy,mm,dd,hh = splitdate(yyyymmddhh)

 give an date string (yyyymmddhh) return integers yyyy,mm,dd,hh.
    """
    yyyy = int(yyyymmddhh[0:4])
    mm = int(yyyymmddhh[4:6])
    dd = int(yyyymmddhh[6:8])
    hh = int(yyyymmddhh[8:10])
    return yyyy,mm,dd,hh

def makedate(yyyy,mm,dd,hh):
    """
 yyyymmddhh = makedate(yyyy,mm,dd,hh)

 return a date string of the form yyyymmddhh given integers yyyy,mm,dd,hh.
    """
    return '%0.4i'%(yyyy)+'%0.2i'%(mm)+'%0.2i'%(dd)+'%0.2i'%(hh)

def daterange(date1,date2,hrinc):
    """
 date_list = daterange(date1,date2,hrinc)

 return of list of date strings of the form yyyymmddhh given
 a starting date, ending date and an increment in hours.
    """
    date = date1
    delta = datetime.timedelta(hours=1)
    yyyy,mm,dd,hh = splitdate(date)
    d = datetime.datetime(yyyy,mm,dd,hh)
    n = 0
    dates = [date]
    while date < date2:
       d = d + hrinc*delta
       date = makedate(d.year,d.month,d.day,d.hour)
       dates.append(date)
       n = n + 1
    return dates

# set range of dates
date1 = '2016030412'
date2 = '2016040100'
hrinc = 6

# parameters
# phis/lnps/tmp/spfh/ugrd/vgrd/o3mr
# "129/152/130/133/131/132/203"


# number of vertical levels.
nlevs = 137
levelist = []
for nlev in range(1,nlevs+1):
    levelist.append('%s/' % nlev)
levelist137 = ''.join(levelist)[:-1]

# output grid
grid = 'F400' # 800 latitude gaussian grid. F1280,F640 also supported.

# get data one date and field at a time.
server = ECMWFService('mars')
for date in daterange(date1,date2,hrinc):
    yyyy,mm,dd,hh = splitdate(date)
    print "requesting 2d fields for %s ...." % date
    server.execute({
        'stream'    : "oper",
        'class'     : "od",
        'expver'    : "69",
        'levtype'   : "ml",
        'type'      : "an",
        'param'     : "129/152",
        'date'      : "%04i-%02i-%02i" % (yyyy,mm,dd),
        'time'      : "%02i" % hh,
        'type'      : "an",
        'levelist'  : "1" ,
        'grid'      : "%s" % grid},
        "/nas/jwhitaker/ifsanl/ifsanl_2d_%s_%s.grib" % (grid,date))
    print "requesting 3d fields for %s ...." % date
    server.execute({
        'stream'    : "oper",
        'class'     : "od",
        'expver'    : "69",
        'levtype'   : "ml",
        'type'      : "an",
        'param'     : "130/133/131/132/203",
        'date'      : "%04i-%02i-%02i" % (yyyy,mm,dd),
        'time'      : "%02i" % hh,
        'type'      : "an",
        'levelist'  : "%s" % levelist137,
        'grid'      : "%s" % grid},
        "/nas/jwhitaker/ifsanl/ifsanl_3d_%s_%s.grib" % (grid,date))
