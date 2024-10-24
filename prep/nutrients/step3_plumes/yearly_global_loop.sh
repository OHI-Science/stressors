
# this executes all steps for creating a final, mosaiced plume raster over a series of pourpoint shapefiles 


cd /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes

# Load ocean mask null into grass session 
r.in.gdal /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata/location/PERMANENT/ocean_mask.tif output='ocean'

outdir=/home/shares/ohi/stressors_2021/_dataprep/nutrients/output/N_plume

j=0

for file in /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/shp/*.shp ; do

# file='SSP5_near-term'

    fileout=${file%.shp}_joined.tif #define output filename  
    j=$(( j + 1 ))
    
    # import the pourpoint vector file into the grass session 
	v.import ${file} output='pours' --overwrite #import the file


    # # clean up any previous pour points (maybe expand these out):
    # removes pour_point rasters and vectors from current grass session

    g.remove -f type=raster pattern=pours_*
    g.remove -f type=vector pattern=pours_*
    g.remove -f type=raster pattern=plume_effluent_*_*
   
    # removes plume rasters from current grass session (note this pattern is from OHI not MAR)

    g.list type=rast pattern=plume_pest* > plume_raster.list
    g.list type=rast pattern=plume_fert* >> plume_raster.list

    for i in `cat plume_raster.list`; do
        echo "Processing ${i}..."
        g.remove rast=$i
    done


    echo "finished cleaning out old stuff"

    # Run the python plume script - this will create rasters in the "grass cloud"
    python2 ./plume_buffer.py pours effluent > ./plume_buffer.log

    echo "ran plumes model"

    # Export the rasters to tif files

    # Make output directory to export rasters in the grass cloud to
    mkdir /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/output 
    cd /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/output

    # Get the list of rasters (pull down from cloud into a list)
    g.list type=raster pattern=plume_effluent* > plume_raster.list

    # export the rasters from the list into the output folder
    for i in `cat plume_raster.list`; do
        echo "Processing ${i}..."
        g.region rast=$i
        r.mapcalc "plume_temp = if(isnull(${i}),0,${i})"
        r.out.gdal --overwrite input=plume_temp output=$i.tif type=Float32
        g.remove -f type=raster name=plume_temp 
    done


## Now we need to combine these rasters into one using the mosaic code: 
## Split the plume output .tifs (this depends on you machine but is required on Mazu @ NCEAS) 
## and put them together 

cd /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/output
mkdir -p subsets

for i in $(seq 1 10); do
   printf "Starting $i \n"
   mkdir -p subsets/subset$i
  
   # move the tif files in batches of 10000 
  find . -maxdepth 1 -name "*.tif" | head -10000 | while read file; do mv "$file" subsets/subset$i; done

   # mosaic subset 
   cd subsets/subset$i/

    python3 /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/gdal_add.py -o effluent_sub$i.tif -ot Float32 plume_effluent*.tif

   printf "subset $i tif done \n"
  
   # move subset mosaic and go up
   mv effluent_sub$i.tif ../
   cd ../..
   
   printf "\n Ending $i \n"
done

printf "Done Subsets \n"

# final mosaic
cd subsets

python3 /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/gdal_add.py -o $fileout -ot Float32 effluent_sub*.tif # ALWAYS UPDATE tif NAME

echo "finished mosaic"

	mv $fileout $outdir #move the mosaic tif file to the output directory defined above

    cd /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes
    
	mv /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/output /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/output$j # rename output so that we can see which plumes it breaks on, if it breaks

done #end loop

#exit grass

