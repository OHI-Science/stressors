## Wastewater Project: Plume model 

channels:
  - conda-forge
  - defaults
solver: classic


How to run the plume model! 

 - Download this "STEP5_plumes" folder into whatever directory you want to run it. For OHI this will be `/home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v20XX/`, and name it "plumes". **YOU WILL NEED TO UPDATE ALL THE FILEPATHS IN `readme.md` and `yearly_global_loop.sh` IF YOU WANT ANY OF THIS TO WORK.** 
 - Download the anaconda installer for 64-bit (x86) linux from https://www.anaconda.com/products/individual (scroll way down the page). Throw the file into your home directory on mazu (or Aurora if that is what you use). You will end up with a folder akin to /home/username/anaconda3
- Install using these instructions:
To install Anaconda on a Linux server, you can follow these steps:

Open a terminal window on your Linux server (this the "Terminal" tab in Rstudio).

Navigate to the directory where you downloaded the Anaconda installation script.

Make the installation script executable by running the following command:

chmod +x Anaconda3-<version>-Linux-x86_64.sh
Replace <version> with the actual version number you downloaded.

Run the installation script by executing the following command:

./Anaconda3-<version>-Linux-x86_64.sh
Again, replace <version> with the correct version number.

Follow the prompts in the installer. You'll be asked to review the license agreement and accept it. Then, you'll be prompted to choose the installation location. You can either accept the default location or specify a different one.

After installation, you'll be asked if you want to initialize Anaconda by running conda init. It is recommended to respond with "yes" so that the conda command is available in your terminal.

Close the terminal window and open a new terminal to ensure the changes take effect.

Verify the installation by running the following command:

conda --version
If the installation was successful, it should display the version number of Conda.

Congratulations! Anaconda is now installed on your Linux server. You can start using it by running conda commands to manage your Python environments and packages.C

 - In your terminal, ssh into mazu.. i.e. `ssh username@mazu.nceas.ucsb.edu` and enter your password
 - Create a folder in your "anaconda3/envs" folder named "py2", this will be your python environment. This can be done with this line `conda create --name py5 python=3`
 - Type `conda activate py2` in your terminal. This will activate this py2 environment and act as your python environment. 
 - Install gdal by typing `conda install -c conda-forge gdal` to install gdal in your python environment. 
 - I recommend using [screens](http://www.kinnetica.com/2011/05/29/using-screen-on-mac-os-x/) in the terminal, so you can turn on the plumes model and leave it running.
    + you can also use [tmux](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/) in [iTerm2](https://iterm2.com/), Maddie found this easier to download and use
 - Follow the steps outlined below, updating file paths as needed: 

 ```
# this is all done in the shell
# NOTE: CHANGE THE filepath to whatever you are using. 
# After creating a new python env, I.e. py2: 

# start a tmux session, so the process can run in the background (see below for more info)
tmux new -s plumes


conda activate py5

mkdir /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata

## Create a folder in your mazu home drive (or wherever you want to run the plumes... for OHI this will be `/home/shares/ohi/git-annex/globalprep/prs_land-based_nutrient/v20XX`) entitled "grassdata" or something of the like.

cp /home/shares/ohi/stressors_2021/_dataprep/nutrients/watersheds_pourpoints/ocean_mask.tif /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata

## copy the ocean mask to YOUR grassdata folder (meaning change the filepath...). The ocean mask is a raster where the land values are set to nan and the ocean values to 1.
rm -r /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata/location # replace filepath with your filepath

grass -c /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata/ocean_mask.tif /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata/location ## start a grass session and create a location folder where grass will run 

exit ## exit grass, and copy ocean_mask.tif to PERMANENT folder, located in location folder

cp /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata/ocean_mask.tif /home/shares/ohi/stressors_2021/_dataprep/nutrients/grassdata/location/PERMANENT
# Move your pourpoint files into a folder in plumes. 

##first create the folder, called "shp" 
rm -r /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/shp # remove old shps
 
mkdir /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/shp # make new shps folder

## navigate to the folder they were saved 

cd /home/shares/ohi/stressors_2021/_dataprep/nutrients/plume_data/
## copy files to the new shp folder you just created. These shapefiles are shapefiles with pourpoints and the associated amount of nutrient aggregated to each pourpoint.

cp SSP* /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/shp
# get back to the plumes directory

cd /home/shares/ohi/stressors_2021/_dataprep/nutrients/plumes/

#mkdir /home/shares/ohi/stressors_2021/_dataprep/nutrients/output
#mkdir /home/shares/ohi/stressors_2021/_dataprep/nutrients/output/N_plume
# make sure you start the loop in plumes. location is very important for the loop to run!

grass  ## enter grass again
# Now run yearly_global_loop.sh #this contains all the code needed. edit file paths if needed (right now they are absolute), especially "outdir" which is the directory the final tif files will be added. once finished, it should plop 15 joined tif files (1 for every year) into whatever was defined as "outdir"

sh yearly_global_loop.sh
exit # exit grass

# To see tmux sessions: tmux ls
# Detach from the Session: To leave the process running in the background and return to  your regular shell, you can detach from the tmux session. To do this, press Ctrl-b followed by d. This will detach your tmux session but leave your processes running.

Reattach to the Session: If you want to check on your process, you can reattach to your tmux session. If you named your session (e.g., "mysession"), you can reattach with the following command:
# tmux attach -t mysession
# To see sessions:
# tmux ls 
# To kill session:
# tmux kill-session -t my-session


# Tips for troubleshooting
## create a messages.txt in your plumes folder and run this to see how far the loop got: 
sh yearly_global_loop.sh > messages.txt
```