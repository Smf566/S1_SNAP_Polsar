"Set up a base working directory and download the three folders from the GitHub"



"############################# Stage 3.1 ###########################################"
" Prepare the directories and the base files to process the images "

library(xml2)

# Directory of the project 
"Replace this path with the base working directory you created" 
base_wd <- "F:\\S1_SNAP_Polsar\\" 


"Run the Script"

#  Directory to the s1 zip files 
zip_wd <- paste0(base_wd, "s1_slc_files\\")

#  Directory to the base graph 
graph_wd <- paste0(base_wd, "base_graph\\")


# -----------------------------------
# Path to save the new graphs 
out_graph_path <- paste0(base_wd, "new_graphs\\")
dir.create(out_graph_path, recursive = TRUE)

# Path to save processes S1 files
out_hdr_path <- paste0(base_wd, "snap_output\\")
dir.create(out_hdr_path, recursive = TRUE)


# -----------------------------------
# Get SNAP base graph
iw_graph <- list.files(graph_wd, glob2rx("*.xml$"), full.names = TRUE)

# Get input sentinel zip files
s1_zip_list <- list.files(paste0(zip_wd), glob2rx("*.zip$"), full.names = TRUE)


# -----------------------------------
# Select the IW numbers for processing 
IW_number = list("IW1", "IW2", "IW3")


"#######################  Step 02 A : SNAP Processing  #######################"


"####################################################"
"Generate Graphs for Each S1 File (within R)"

# Load necessary libraries
library(xml2)
library(stringr)
library(tools)

for (file in s1_zip_list){
  
  for (i in IW_number){
    # -----------------------------------
    "Swath IW"
    
    # Read the XML graph template
    snap_xml_graph <- read_xml(iw_graph)
    
    # Locate the iw node of the graph
    topsar_split_node <- xml_child(xml_children(snap_xml_graph)[3][[1]], 3)
    
    # Find the subswath node within the parameters of TOPSAR-Split
    subswath_node <- xml_find_first(topsar_split_node, ".//subswath")
    
    # Assign the subswath value to the subswath node
    xml_text(subswath_node) <- paste0(i)  # Replace with your desired subswath value
    
    # Save the modified write node as an XML document
    as_xml_document(subswath_node)
    
    # -----------------------------------
    "Read Node"
    
    # Input name of the s1 file as .zip
    input_tag <- file[1]
    
    # Locate the "read" node of the graph
    read_node <- xml_child(xml_children(snap_xml_graph)[2][[1]], 3)
    
    # Find the filename node within the read node
    read_file_node <- xml_find_first(read_node, ".//file")
    
    # Assign the input_tag to the filename node
    xml_text(read_file_node) <- input_tag
    
    # Save the modified read node as an XML document
    as_xml_document(read_node)
    
    
    # -----------------------------------
    "Write Node"
    
    # Input name of the s1 file as .zip
    
    iw_identifier <- paste0(i)
    output_name <- gsub(".zip", paste0("_",iw_identifier, ".hdr") ,basename(file[1]))
    output_tag <- paste0(out_hdr_path, output_name)
    
    # Locate the "write" node of the graph
    write_node <- xml_child(xml_children(snap_xml_graph)[9][[1]], 3)
    
    # Find the filename node within the write node
    write_file_node <- xml_find_first(write_node, ".//file")
    
    # Assign the output_tage for the write file node
    xml_text(write_file_node) <- output_tag
    
    # Save the modified write node as an XML document
    as_xml_document(write_node)
    
    # Define the path to save the modified XML graph
    modified_graph_path <- paste0(out_graph_path, paste0(basename(output_tag), ".xml"))
    
    # Write the modified XML graph to the specified file
    write_xml(snap_xml_graph, file = modified_graph_path)
  }
  
}




"####################################################"
"Batch processing of SNAP graphs"

# Load necessary library for parallel processing
library(parallelMap)

# Set number of cores to use on your PC
cores_nr <- 2

# Get the list of newly created SNAP processing graphs
iw_graph_list_new <- list.files(out_graph_path,
                                glob2rx("*.xml$"), full.names = TRUE)

iw_graph_list_new <- iw_graph_list_new[1:4]

# Initialize parallel processing with the specified number of cores
parallelMap::parallelStartSocket(cores_nr)

# Export the list of new SNAP processing graphs to the parallel workers
parallelMap::parallelExport('iw_graph_list_new')

# Apply the SNAP processing graphs in parallel
# The 'gpt' command is used to process each graph file
parallelMap::parallelLapply(iw_graph_list_new, function(iw_file_name) {
  system(paste0("gpt ", iw_file_name))
})

# Stop the parallel processing
parallelMap::parallelStop()

# Clean up memory
gc();gc()





"#######################  Step 02 B : PolSARpro Processing  #######################"


"####################################################"
"Data configuration"
"Edit the config.txt file > 'dual' to 'pp2'"


# Get the list of processed Sentinel-1 files 
file_list <- list.dirs(out_hdr_path)[-1]

# Iterate over each folder containing processed SNAP output
for (file in file_list) {
  
  # Read the config.txt file
  config_file <- readLines(paste0(file, "/config.txt"))
  
  # Substitute "dual" with "pp2"
  config_file <- gsub("dual", "pp2", config_file)
  
  # Substitute "dual" with "pp2"
  writeLines(config_file, paste0(file, "/config.txt"))
  
}




"####################################################"
"Generation of C2 folder and preserving geo-spatial information"

# Assign cores for parallalization
cores_process <- 2

# Initialize parallel processing
parallelMap::parallelStartSocket(cores_process)

# Export the list of folders to parallel workers
parallelMap::parallelExport("file_list")

# Load necessary library for raster operations
parallelMap::parallelLibrary("raster")

# Apply the following process in parallel for each folder in file_list
parallelMap::parallelLapply(file_list, function (file){
  
  ## 01 ---------------------------------------------------------------------------
  # Move files to C2 folder
  
  # Get all the files within the folder
  all_file_list <-list.files(file, full.names = TRUE)
  
  # Create a directory named "C2"
  dir.create(paste0(file, "/C2"), recursive = TRUE, showWarnings = TRUE)
  
  # Copy all files to C2 folder
  lapply(all_file_list, function(x) {
    file.copy(x, paste0(file, "/C2/", basename(x)))
  })
  
  # Delete the original files
  unlink(all_file_list, recursive = TRUE)
  
  
  ## 02 ---------------------------------------------------------------------------
  # Get reference file to create a geotiff for spatial extent
  
  # Use C11.bin file to get the spatial information of the image
  ref_geotif_raster <- raster::raster(paste0(file, "/C2/C11.bin"))
  
  # Save the raster 
  raster::writeRaster(ref_geotif_raster, paste0(file, "/", basename(file), ".tif"))
})

# Stop parallel processing
parallelMap::parallelStop()







"####################################################"
"Generating PolSARpro parameters"


# Assign cores for parallelization
cores_process <- 2

# Get the list of folders containing 'C2' subfolders within the Sentinel-1 folders
file_list <- list.dirs(base_wd)[-1][grep("/C2", list.dirs(base_wd)[-1])]

# Initialize parallel processing
parallelMap::parallelStartSocket(cores_process)

# Export the list of folders to parallel workers
parallelMap::parallelExport("file_list")

# Load necessary library for raster operations
parallelMap::parallelLibrary("raster")

# Apply the following processes in parallel for each 'C2' folder in file_list
parallelMap::parallelLapply(file_list, function (file_c2_folder){
  
  
  #  Extract information from config.txt file
  row_col <- as.integer(readLines(paste0(file_c2_folder, "/config.txt"))[c(2, 5)]) # Get the number of rows and columns 
  idf_string <- "C2" #  input data format
  ofr_int <- 0 #  Offset Row
  ofc_int <- 0 # Offset Col
  fnr_int <- row_col[1] #  Final Number of Row
  fnc_int <- row_col[2] # Final Number of Col
  
  
  #  Create mask valid pixels
  cmd_string_mask <- paste0('create_mask_valid_pixels',
                            ' -id ', file_c2_folder,
                            ' -od ', file_c2_folder,
                            ' -idf ', idf_string,
                            ' -ofr ', ofr_int, 
                            ' -ofc ', ofc_int, 
                            ' -fnr ', fnr_int, 
                            ' -fnc ', fnc_int)
  # Run the mask command
  system(cmd_string_mask) # This will only create the BIN file, not the HDR and the BMP file associated with it
  
  
  
  # Create mask BMP file 
  # Get the mask file created in previous step (3.1)
  mask_file <- paste0(file_c2_folder, "/mask_valid_pixels.bin")
  cmd_string_bmp <- paste0('create_bmp_file -mcol black -if "', mask_file, '"',
                           ' -of "', gsub(".bin", ".bmp", mask_file), '"',
                           ' -ift float -oft real -clm "jet" -nc ', fnc_int, 
                           ' -ofr 0 -ofc 0 -fnr ', fnr_int, ' -fnc ', fnc_int, 
                           ' -mm 0 -min 0 -max 1 -mask "', mask_file, '"')
  # Run the BMP command
  system(cmd_string_bmp) # This wil create the HDR and the BMP file for the mask_valid_pixels
  
  
  
  #  Process parameters
  
  # Create a file to save any errors
  err_string <- paste0(dirname(file_c2_folder), "/MemoryAllocError.txt")
  
  # --------------------------------
  #  C11 Element
  cmd_string_c11 <- paste0('process_elements -id "', file_c2_folder, '"',
                           ' -od "', file_c2_folder, '"',
                           ' -iodf C2 -elt 11 -fmt mod -ofr 0 -ofc 0 -fnr ',
                           fnr_int, ' -fnc ', fnc_int, ' -errf "', err_string, '"',
                           ' -mask "', mask_file, '"')
  # Run the C11 element command
  system(cmd_string_c11) # This will only create the BIN file, not the HDR file associated with it
  
  
  
  # --------------------------------
  #  C22 Element
  cmd_string_c22 <- paste0('process_elements -id "', file_c2_folder, '"',
                           ' -od "', file_c2_folder, '"',
                           ' -iodf C2 -elt 22 -fmt mod -ofr 0 -ofc 0 -fnr ',
                           fnr_int, ' -fnc ', fnc_int, ' -errf "', err_string, '"',
                           ' -mask "', mask_file, '"')
  system(cmd_string_c22)
  # This will only create the BIN file, not the HDR file associated with it
  
  
  
  # --------------------------------
  #  Span
  cmd_string_span <- paste0('process_span -id "', file_c2_folder, '"',
                            ' -od "', file_c2_folder, '"',
                            ' -iodf C2 -fmt lin -nwr 1 -nwc 1 -ofr 0 -ofc 0 -fnr ', fnr_int, 
                            ' -fnc ', fnc_int,
                            ' -errf "', err_string, '"',
                            ' -mask "', mask_file, '"')
  # Run the span command
  system(cmd_string_span)
  
  
  # --------------------------------
  #  Stokes
  cmd_string_stokes <- paste0('stokes_parameters -id "', file_c2_folder, '"',
                              ' -od "', file_c2_folder, '"',
                              ' -iodf C2 -nwr 5 -nwc 5 -ofr 0 -ofc 0 -fnr ', fnr_int, ' -fnc ', fnc_int,
                              ' -cha 2 -fl1 1 -fl2 1 -fl3 1 -fl4 1 -fl5 1 -fl6 1 -fl7 1 -fl8 0 -fl9 0 -fl10 0 -fl11 0 -fl12 1 -fl13 0 -fl14 1 -fl15 0 -fl16 0',
                              ' -errf "', err_string, '"',
                              ' -mask "', mask_file, '"')
  # Run the Stokes command
  system(cmd_string_stokes) # This will only create the BIN file, not the HDR file associated with it
  
  
  # --------------------------------
  #  H_Alpha
  cmd_string_h_alpha <- paste0('h_a_alpha_decompositionSPPC2 -id "', file_c2_folder, '"',
                               ' -od "', file_c2_folder, '"',
                               ' -iodf C2 -nwr 5 -nwc 5 -ofr 0 -ofc 0 -fnr ', fnr_int, ' -fnc ', fnc_int,
                               ' -fl1 0 -fl2 0 -fl3 0 -fl4 0 -fl5 0 -fl6 1 -fl7 0 -fl8 0 -fl9 1 -fl10 0 -fl11 0 -fl12 0 -fl13 0 -fl14 0 -fl15 1',
                               ' -errf "', err_string, '"',
                               ' -mask "', mask_file, '"')
  # Run the H_Alpha command
  system(cmd_string_h_alpha) # This will only create the BIN file, not the HDR file associated with it
  
  
})

# Stop parallel processing
parallelMap::parallelStop()







"####################################################"
" Generate ENVI (.HDR) Files "

# Load necessary library for raster operations
library(raster)

# Collect the list of C2 folders within the Sentinel-1 folders
folder_list <- list.dirs(base_wd)[-1][grep("/C2", list.dirs(base_wd)[-1])]

# Iterate over each folder in the folder list 
for (folder in folder_list){
  
  # Get the list of BIN files within the folder
  bin_files <- list.files(paste0(folder), pattern = "\\.bin$", full.names = TRUE)
  
  # Get the list of BIN files within the folder
  for (file in bin_files) {
    
    # Set the name of the HDR file
    bin_name_1 <- basename(file)
    bin_name <- gsub(".bin", "", bin_name_1)
    
    # Determine the path for the output HDR file
    hdr_output <- file.path(folder, paste0( bin_name_1, ".hdr"))
    
    # Skip if HDR file already exists
    if (file.exists(hdr_output)) {
      next # Skip to the next BIN file
    }
    
    # Get the original C11 .hdr file 
    hdr_files <- list.files(paste0(folder), pattern = 'C11.bin.hdr', full.names = TRUE)
    header_lines <- readLines(hdr_files)
    
    # Rename the band name 
    editted_hdr <- gsub("band names = \\{ C11 \\}", paste0("band names = { ", bin_name, " }"), header_lines)
    
    # write the HDR file 
    writeLines(editted_hdr, hdr_output)
  }
}





"####################################################"
" Generate raster files for each parameter "

# Load necessary libraries
library(parallelMap)
library(beepr)

# Collect the list of C2 folders within the Sentinel-1 folders
folder_list <- list.dirs(base_wd)[-1][grep("/C2", list.dirs(base_wd)[-1])]

# Set the target spatial resolution
target_res <- 10

# Set the number of cores to use for parallel processing
cores_process <- 2

# Error reporting
error_status_file <- paste0("F:\\new_s1_cmd\\status_report.txt")
cat("List of bin file to reprocess:\n\n", file = error_status_file)

# Start parallel processing with the specified number of cores
parallelStartSocket(cores_process)

# Export variables 'folders', 'target_res', and 'error_status_file' to parallel workers
parallelExport("folder_list", "target_res", "error_status_file", "base_wd")

# Load the 'raster' library in parallel workers to enable raster processing functions
parallelMap::parallelLibrary("raster") 

# Define a function to process SAR images in each folder
parallelLapply(folder_list, function(x) {
  
  # Extract the basename of the directory
  folder_name <- basename(dirname(x))
  
  # Create output directory based on the folder name
  geotif_output_path <- file.path(base_wd, "tiff_folder", folder_name)
  dir.create(geotif_output_path, recursive = TRUE)
  
  # Read the reference raster file (.tif) in the folder
  spatial_tiff <- list.files(dirname(x), pattern = '.tif', full.names = TRUE)
  
  # Convert raster files to raster objects
  spatial_tiff <- raster::raster(spatial_tiff)
  
  # Extract spatial data from raster objects
  spatial_tiff <- as(spatial_tiff, "SpatialGridDataFrame")
  
  # Get binary files in the 'C2' subfolder
  bins <- list.files(x, pattern=glob2rx('*.bin$'), full.names = TRUE)
  
  # Convert meters to decimal degrees for spatial resolution
  spatial_res_dd <- (target_res / 111) * 0.001
  
  # Iterate over each BIN file
  for (i in bins) {
    
    # Check if binary file is valid based on size
    file_size <- file.info(i)$size
    if (file_size > 300000) {
      
      # Set output file name
      out_name <- gsub(".bin", '.tif', basename(i))
      
      # Read binary data and assign to spatial raster
      spatial_tiff1 <- spatial_tiff
      spatial_tiff1@data <- data.frame(values = rgdal::readGDAL(i)$band1)
      
      # Convert to Terra raster
      spatial_tiff1 <- terra::rast(spatial_tiff1)
      
      # Project to EPSG:4326 coordinate system
      spatial_tiff1 <- terra::project(spatial_tiff1, "EPSG:4326")
      
      # Create temporary raster for resampling
      temp_rast <- terra::rast(terra::ext(spatial_tiff1), res = spatial_res_dd)
      
      # Resample raster
      spatial_tiff1 <- terra::resample(spatial_tiff1, temp_rast)
      
      # Remove temporary raster and perform garbage collection
      rm(temp_rast)
      gc()
      gc()
      
      # Set output path for GeoTIFF
      out_bin_tif <- paste0(geotif_output_path, "/", out_name)
      
      # Write resampled raster to GeoTIFF
      terra::writeRaster(spatial_tiff1, out_bin_tif,
                         overwrite = TRUE,
                         datatype = "FLT4S", # float 32 datatype
                         NAflag = -32767, # no data value
                         gdal = "COMPRESS=DEFLATE") # standard compression
      
      # Write file name to status report if file size is below a threshold
      if (file.info(out_bin_tif)$size < 500000000) {
        cat(paste0(basename(geotif_output_path), "\n"), file = error_status_file, append = TRUE)
      }
    }
  }
  
})

# End parallel processing
parallelStop()
beep()
beep()
beep()
beep()


"###############################################################################"
"###############################################################################"
