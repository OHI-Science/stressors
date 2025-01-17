## Spatial files from:
https://github.com/mapping-marine-spp-vuln/spp_vuln_mapping
by: Casey O'Hara!

input data:
- ne_10m_land: Natural Earth shapefile
- ne_10m_ocean: Natural Earth shapefile
- rgns_mol_1k.gpkg: Spatial files from the Ocean Health Index regions
- eez_rgn_names: Spatial files from the Ocean Health Index csv files with region information


The set_up_master_rasters.Rmd (by Casey): prepares these files:
- rast_base_mol_10km.tif: template raster used to get other spatial files
- ocean_area_mol.tif: area of ocean in each 10km raster cell 
- eez_mol.tif: 10km raster of marine areas, with IDs as OHI region IDs
- eez_mol_w_land.tif: 10km raster of land and marine areas with IDs as OHI region IDs


The prepare_coastal_raster.Rmd prepares:
coastal_country_mol.tif which identifies the cells along the coastline with IDs as OHI region IDs