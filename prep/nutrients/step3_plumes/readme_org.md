## Wastewater Project: Plume model 

How to run the plume model! 
 
 - Download this "STEP5_plumes" folder into whatever directory you want to run it. For OHI this will be `/home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v20XX/`, and name it "plumes". **YOU WILL NEED TO UPDATE ALL THE FILEPATHS IN `readme.md` and `yearly_global_loop.sh` IF YOU WANT ANY OF THIS TO WORK.** 
 - Go ahead and install the anaconda installer for 64-bit (x86) linux from https://www.anaconda.com/products/individual and throw the file into your home directory on mazu (or Aurora if that is what you use). You will end up with a folder akin to /home/username/anaconda3
 - In your terminal, ssh into mazu.. i.e. `ssh username@mazu.nceas.ucsb.edu` and enter your password
 - Create a folder in your "anaconda3/envs" folder named "py2", this will be your python environment. This can be done with this line `conda create --name py2 python=2`
 - Type `conda activate py2` in your terminal. This will activate this py2 environment and act as your python environment. 
 - Install gdal by typing `conda install -c conda-forge gdal` to install gdal in your python environment. 
 - I recommend using [screens](http://www.kinnetica.com/2011/05/29/using-screen-on-mac-os-x/) in the terminal, so you can turn on the plumes model and leave it running.
    + you can also use [tmux](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/) in [iTerm2](https://iterm2.com/), Maddie found this easier to download and use
 - Follow the steps outlined below, updating file paths as needed: 
 
 ```
# this is all done in the shell
# NOTE: CHANGE THE filepath to whatever you are using. 

# After creating a new python env, I.e. py2: 

conda activate py2

mkdir /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/grassdata
## Create a folder in your mazu home drive (or wherever you want to run the plumes... for OHI this will be `/home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v20XX`) entitled "grassdata" or something of the like.

cp /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/int/ocean_masks/ocean_mask.tif /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/grassdata

## copy the ocean mask to YOUR grassdata folder (meaning change the filepath...). The ocean mask is a raster where the land values are set to nan and the ocean values to 1.

rm -r /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/grassdata/location # replace filepath with your filepath

grass -c /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/grassdata_testing/ocean_mask.tif /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/grassdata/location ## start a grass session and create a location folder where grass will run 

exit ## exit grass, and copy ocean_mask.tif to PERMANENT folder, located in location folder

cp /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/grassdata/ocean_mask.tif /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/grassdata/location/PERMANENT

# Move your pourpoint files into a folder in plumes. 
##first create the folder, called "shp" 

rm -r /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/plumes/shp # remove old shps
 
mkdir /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/plumes/shp # make new shps folder

## navigate to the folder they were saved to which in my case is the prs_land-based_nutrient/v2021 folder

cd /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/int/pourpoints/

## copy files to the new shp folder you just created. These shapefiles are shapefiles with pourpoints and the associated amount of nutrient aggregated to each pourpoint.

cp pourpoints_* /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/plumes/shp

# get back to the plumes directory

cd /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/plumes/

mkdir /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/output
mkdir /home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v2022/output/N_plume

# make sure you start the loop in plumes. location is very important for the loop to run!

grass ## enter grass again

# Now run yearly_global_loop.sh #this contains all the code needed. edit file paths if needed (right now they are absolute), especially "outdir" which is the directory the final tif files will be added. once finished, it should plop 15 joined tif files (1 for every year) into whatever was defined as "outdir"

sh yearly_global_loop.sh

exit # exit grass

# Tips for troubleshooting
## create a messages.txt in your plumes folder and run this to see how far the loop got: 

sh yearly_global_loop.sh > messages.txt

```

