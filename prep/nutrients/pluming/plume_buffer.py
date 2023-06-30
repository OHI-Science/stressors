#!/usr/bin/env python3
"""
plume_buffer.py
GRASS GIS model to generate plumes of material transport based on vector attributes.

Requires a raster ocean mask named ocean in the mapset.  Ideally, place this 
mask in the PERMANENT folder of the mapset.

Authors: Matthew T. Perry, Shaun C. Walbridge
""" 

import sys
import os
import math
import glob
import subprocess

def getArgs():
    try:
        vname = sys.argv[1]
        if len(sys.argv) == 3:
            attribs = [sys.argv[2]]
        else:
            # default attributes to analyze
            #attribs = ['SUM_IMPV','SUM_PESTC','SUM_FERTC']
            attribs = ['SUM_PESTC','SUM_FERTC']
        return vname,attribs
    except:
        print(sys.argv[0], " usage: <vname name> {attribute}")
        sys.exit(1)

def getCatList(vname,attribs):
    catlist = {}

    cmd = "v.db.select -c map=%s column=cat,basin_id,%s" % (vname,','.join(attribs))
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True).decode().strip().split('\n')

    for i in lines:
        pair = i.split('|')
        cat = pair[0]
        basin = pair[1]

        catlist[cat] = {'basin_id': basin, 'attribs' : {}}
        if len(attribs) == 1:
            catlist[cat]['attribs'][attribs[0]] = pair[2]
            catlist[cat]['max'] = float(pair[2])
        else:
            for i in range(len(attribs)):
                name = getName(attribs[i])
                # find max value
                if 'max' in catlist[cat]:
                    catlist[cat]['max'] = max(float(pair[i+2]),   \
                                              catlist[cat]['max'])
                else:
                    catlist[cat]['max'] = float(pair[i+2])

                catlist[cat]['attribs'][name] = float(pair[i+2])

    return catlist

def cleanHouse(vname,categories):
    # Modified by jkibele April 2019 for use with grass76
    cmd = "g.remove -f type=vector pattern={}_*".format(vname)
    lines = subprocess.check_output(cmd, shell=True).decode().strip().split('\n')

    
    raster_patterns = [
        "{}_*".format(vname),
        "{}_buff_*".format(vname),
        "{}_cost_*".format(vname),
        "{}_dw_*".format(vname),
    ]
    for rp in raster_patterns:
        cmd = "g.remove -f type=raster pattern={}".format(rp)
        os.popen(cmd)
    
    ## This doesn't work with grass76 - jkibele
    # for (c, c_data) in categories.items():
    #     basin_id = c_data['basin_id']
    #     rasters  = ['%s%s%s' % (vname, r, basin_id) for \
    #                r in ['_', '_buff_', '_cost_', '_dw_']]
    #     cmd = "g.remove vect=%s_%s" % (vname, basin_id)
    #     os.popen(cmd)
    #     
    #     cmd = "g.remove rast=%s" % (','.join(rasters))
    #     os.popen(cmd)

    return True

def getName(name):
    # map column names to clean ones
    names = {'SUM_FERTC': 'fert',
             'SUM_PESTC': 'pest',
             'SUM_IMPV' : 'impv',
             'z_inorg' : 'inorganic',
             'z_nutri' : 'nutrients',
             'z_organ' : 'organic',
             'Sed_Increa' : 'sed_increase',
             'Sed_Decrea' : 'sed_decrease'}
    if name in names:
        return names[name]
    else:
        return name

def getEnv():
    cmd = "g.gisenv"
    print("cmd: {}".format(cmd))
    lines = os.popen(cmd).read().rstrip().replace("'","").replace(';','').split("\n")
    env = {}
    for o in [i.split('=') for i in lines]:
        env[o[0]] = o[1]

    return env

def getPath():
    # return raster path
    env = getEnv()
    return "%s/%s/%s/cellhd/" % (env['GISDBASE'],env['LOCATION_NAME'],env['MAPSET'])
    
def getMaxDist(max):
    # exponents to distance mappings
    exp_distances = { -15 : 5, # SGC added 2021.10.04
          -14 : 5, # SGC added 2021.10.04
          -13 : 5, # CPT added 2020.03.02
		      -12 : 5, # CPT added 2020.03.02
	              -11 : 5, # CPT added 2020.03.02
		      -10 : 5, # CPT added 2020.02.02
		      -9 : 5, # CPT added 2020.02.02
		      -8 : 5, # CPT added 2020.02.02
		      -7 : 5, # CPT added 2020.02.02
		      -6 : 5,
                      -5 : 5,
                      -4 : 10,
                      -3 : 10,
                      -2 : 80,
                      -1 : 120,
                       0 : 200,
                       1 : 220,
                       2 : 230,
                       3 : 240,
                       4 : 250,
                       5 : 260,
                       6 : 270,
                       7 : 280,
                       8 : 300,
                       9 : 320,
                       10 : 350,
		       11 : 370, # CPT added 2020.02.04
		       12 : 400, # CPT added 2020.02.04
		       13 : 430, # CPT added 2020.02.04
		       14 : 450, # CPT added 2020.02.04
		       15 : 480 # CPT added 2020.02.04
                    }

    max_sn = '%e' % max
    exp    = int(max_sn.split('e')[1])

    return exp_distances[exp]

def getLimit(column):
    default = 0.0001 # distribution limit in non-standard columns

    # limits generated by plume_distribution.R
    """
    #original:
    limits = { 'FERTC_SUM': 0.0006000, \
               'PESTC_SUM': 0.0001,    \
               'IMPV_SUM' : 0.0003438557, \
               'z_inorg': 0.00015,      \
               'z_nutri': 0.000003,      \
               'z_ports': 0.00015,      \
               'z_organ': 0.0001,      \
               'Sed_Increa': 0.0001,     \
               'Sed_Decrea': 0.0001     
             }
    """
    #2003-2006
    limits = { 'effluent': 0.00001954467, \
               'FERTC_SUM': 0.000621628, \
               'PESTC_SUM': 0.0000135538,    \
               'IMPV_SUM' : 0.0003438557, \
               'z_inorg': 0.00015,      \
               'z_nutri': 0.000003,      \
               'z_ports': 0.00015,      \
               'z_organ': 0.0001,      \
               'Sed_Increa': 0.0001,     \
               'Sed_Decrea': 0.0001     
             }
    """
    #2007-2010
    limits = { 'FERTC_SUM': 0.0007936084, \
               'PESTC_SUM': 0.0000121545,    \
               'IMPV_SUM' : 0.0003438557, \
               'z_inorg': 0.00015,      \
               'z_nutri': 0.000003,      \
               'z_ports': 0.00015,      \
               'z_organ': 0.0001,      \
               'Sed_Increa': 0.0001,     \
               'Sed_Decrea': 0.0001     
             }
    """

    if column in limits:
        return limits[column]
    else:
        return default

def processCategory(c, c_data, vname, log):
    basin_id = c_data['basin_id']
    maxdist = getMaxDist(c_data['max'])
    columns = c_data['attribs']
    mask = 'ocean@PERMANENT'
    
    # HACK: test for existing pours for restarting semi-complete jobs
    # don't use g.mlist as it drags ass
    plumes_create = []
    plumes = [os.path.basename(g) for g in glob.glob('%s/plume_*_%s' % (getPath(), basin_id))]

    for col in list(columns.keys()):
        pn = 'plume_%s_%s' % (col, basin_id)
        if pn not in plumes:
            plumes_create.append(pn)

    if len(plumes_create) == 0:
        print("\n Plumes exist for %s, skipping.\n" % basin_id)
        with open(log, 'w') as file:
              file.write("%s: all plumes exist, skipping." % basin_id)
        return

    print("\n Processing basin %s \n" % basin_id)
    with open(log, 'w') as file:
        file.write("%s,%s,%s\n" % (c, basin_id, columns))

    # Initialize region to entire map
    cmd = 'g.region raster=%s' % mask
    # print "cmd: {}".format(cmd)
    lines = subprocess.check_output(cmd, shell=True).decode().strip().split('\n')


    # Extract the single point
    pour = '%s_%s' % (vname, basin_id)
    cmd = 'v.extract input=%s output=%s where="cat = %s" new=1' % \
           (vname, pour, c)
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True).decode().strip().split('\n')


    # Subset region down to the narrowest possible buffer map
    cmd = "g.region vector=%s align=%s" % (pour, mask)
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True).decode().strip().split('\n')


    # Find current point region
    cmd = "g.region -gp"
    print("cmd: {}".format(cmd))
    regionsplit = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')
    region = {}
    for r in regionsplit:
       pv = r.strip().split('=')
       if (pv[0] != ''):
           region[pv[0]] = float(pv[1])

    # Extend region based on input value
    cellsize = region['nsres']
    regionbuff = cellsize * maxdist
    n = region['n'] + regionbuff
    s = region['s'] - regionbuff
    w = region['w'] - regionbuff
    e = region['e'] + regionbuff
    cmd = "g.region n=%s s=%s w=%s e=%s align=%s" % (n, s, w, e, mask)
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')

    # Convert to raster
    cmd = "v.to.rast input=%s output=%s use=cat" % \
           (pour, pour) 
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')

    # Buffer point to assure pour point hits coast
    pourbuff = '%s_buff_%s' % (vname, basin_id)
    # I'm using wgs84 so maybe fudge the units to 0.02916655? jk
    cmd ="r.buffer input=%s out=%s distances=3.5 units=kilometers" % \
          (pour, pourbuff)
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')

    dw = '%s_dw_%s' % (vname, basin_id)
    cost = '%s_cost_%s' % (vname, basin_id)

    # Calculate cost distance
    cmd = "r.cost -k input=%s max_cost=%s output=%s start_raster=%s" % \
          (mask, maxdist, cost, pourbuff)
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')

    # Mask out non-ocean cells - TRY COMMENTING OUT THIS PART GAGE 
    cmd = 'r.mapcalc "%s = if( %s, %s)"' % (dw, mask, cost) 
    print("cmd: {}".format(cmd))
    lines = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')

    # Area Weighted distribution of sediment 
    cmd = 'r.stats -c %s' % dw
    print("cmd: {}".format(cmd))
    area_info = lines = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')
    area_list = [i.split(' ') for i in area_info][:-1]

    pct = 0.005  # percentage of material deposited at each buffer ring

    if len(area_list) == 0:
        with open(log, 'w') as file:
            file.write("%s,%s,Area list is zero length, all values are null.\n" % (basin_id,c))
        print("area list null.")
        return

    for (col, value) in list(columns.items()):
        init  = float(value)
        limit = getLimit(col) 
        sum, percell, remain = 0., 0., 0.
        recode_table = ''

        plume = 'plume_%s_%s' % (col, basin_id)
        if init == 0.0 or init == '':s
        with open(log, 'w') as file:
            file.write("%s,%s=%s has a value of 0, skipping.\n" % (basin_id, col, init))

        break

        orig = init
        for (dist,count) in area_list:
            if init * pct < limit:
                remain = 0
                percell = init // float(count)
            else:
                percell = init * pct
                sum = percell * float(count)
                remain = init - sum
            init = remain
            
            # log.write("%2f,%2f,%2f,%2f,%2f\n" % (dist, count, percell, sum, remain))
            # test if we're being handed a continuous raster, which has ranges of values
            #//---------------------modified:------------------
            #if dist.find('-'):
            if dist.find('-') != -1:
                low, high = dist.split('-')
                recode_table += "%s:%s:%s\n" % (low, high, percell)
            else:
                recode_table += "%s:%s:%s\n" % (dist, dist, percell) 

        # Reclass the dw map and recreate the plume map
        cmd = "r.recode input=%s output=%s rules=- <<EOF \n%sEOF" % (dw,plume,recode_table)
        print("cmd: {}".format(cmd))
        lines = subprocess.check_output(cmd, shell=True, universal_newlines=True).strip().split('\n')

    # Clean up
    tmp = {}
    tmp[c] = c_data
    # cleanHouse(vname, tmp)
    #log.flush()

def handle(cmd):
    try:
        handle = os.popen(cmd, 'r', 1)
        return handle
    finally:
        handle.close()

def addPlumes(outputFile, column):
    (name, ext) = os.path.splitext(outputFile)
    batch = 60
    files = glob.glob('plume*.tif*')
    ext   = os.path.splitext(files[0])[1]
    tempids = [os.path.splitext(i)[0] for i in files]
    
    cmd = "g.region raster=ocean"
    handle(cmd)

    calc = []

    for id in tempids:
        cmd = "r.in.gdal -o in=%s%s out=%s" % (id, ext, id)
        handle(cmd)
        calc.append("if (isnull(%s), 0, %s)" % (id, id)) 
    
    print("Merging %i input layers..." % len(calc))

    f = open('mapcalc-expression', 'wb')
    f.write("%s = %s" % (name, " + ".join(calc)))
    f.close()

    cmd = 'r.mapcalc < %s' % f.name
    handle(cmd)

    print("Exporting final layer %s..." % name)
    cmd = "r.out.gdal in=%s out=%s.tiff" % (name, name)
    handle(cmd)

    print("Compressing final layer %s" % name)
    cmd = "gdal_translate %s.tiff -co COMPRESS=PACKBITS %s.tif" % (name, name)
    handle(cmd)

    # delete uncompressed tiff and mapcalc expression
    os.remove('%s.tiff' % name)

if __name__ == '__main__':
    vname, attrib = getArgs()
    categories = getCatList(vname,attrib)

    # create error log file
    logfile = "plume_%s.log" % (vname)

    with open(logfile, 'w') as file:
        file.write('# plume_buffer log output\n')
        file.write('basin_id,category,message\n')

    i = 1
    for (c, c_data) in list(categories.items()):
        print("========  %s of %s (%s percent) ================" % \
               (i,len(categories),int(100 * (float(i)//float(len(categories))))))
        processCategory(c, c_data, vname, logfile)
        with open(logfile, 'a') as file:
            file.write("c_data: {}\n".format(c_data))
        #log.write("%s,%s,%s\n" % (cat,catlist[cat][0],catlist[cat][1]))
        i = i + 1

    """
    for att in attrib:
        addPlumes("%s_%s_total.tif" % (vname, att), att)
    """
   # log.close()
   
   
   
   
   
