# README

## Streamlining Sentinel-1 SLC Product Processing: Parallelization and Optimization for Efficient Decomposition Parameter Extraction using SNAP and PolSARPro

### Keywords
- Sentinel-1
- SNAP
- PolSARpro
- Parallelization
- RStudio
- Batch-processing

---

## Step 1: Installation and Configuration of Software

### Installing Python

Ensure that Python is installed on your system. Follow the instructions at [Python's official website](https://www.python.org/downloads/) to download and install the latest version.

1. Visit the [Python downloads page](https://www.python.org/downloads/).
2. Select the appropriate version for your operating system and click on the download link.
3. Run the installer and follow the prompts. Make sure to check the box that says "Add Python to PATH" during installation.
4. Verify the installation by opening a command prompt or terminal and typing `python --version`.

### Installing RStudio

RStudio is an integrated development environment (IDE) for R.

1. Install R:
   - Visit the [CRAN R Project page](https://cran.r-project.org/).
   - Choose your operating system and follow the instructions to download and install R.
2. Install RStudio:
   - Visit the [RStudio downloads page](https://www.rstudio.com/products/rstudio/download/).
   - Download the appropriate version for your operating system.
   - Run the installer and follow the prompts.
   - After installation, open RStudio and verify it by running a simple R command like `print("RStudio is installed")`.
3. Configure R by adding it to your system's PATH environment variable: 
   - Navigate to the installation directory, typically `C:\Programs\R\bin`.
   - Access system properties by searching for "edit the system variables" and, with administrative privileges, open the Environment Variables panel.
   - In the System Variables section, locate and double-click the "PATH" variable to open the Edit Environment Variable panel.
   - Click "New" and add the path to R's bin directory. Click "OK" to save the changes.


### Installing SNAP

SNAP (Sentinel Application Platform) is a common architecture for all Sentinel Toolboxes.

1. Visit the [SNAP download page](http://step.esa.int/main/download/).
2. Download the installer suitable for your operating system (Windows, macOS, or Linux).
3. Run the installer and follow the prompts to complete the installation.
4. Configure SNAP by adding it to your system's PATH environment variable:
   - Navigate to the installation directory, typically `C:\Programs\snap\bin`.
   - Access system properties by searching for "edit the system variables" and, with administrative privileges, open the Environment Variables panel.
   - In the System Variables section, locate and double-click the "PATH" variable to open the Edit Environment Variable panel.
   - Click "New" and add the path to SNAP's bin directory. Click "OK" to save the changes.
5. Verify the installation by opening a command line and typing `gpt`. You should see a list of SNAP functions and tools.



### Installing PolSARpro

PolSARpro (Polarimetric SAR Data Processing and Educational Tool) is used for processing polarimetric data.

**Installing other software**
1. Visit the [PolSARpro download page](https://www.ietr.fr/polsarpro-bio/).
2. Open the README file appropriate for your operating system. 
3. Download and install all the software mentioned within the document (Tcl, Gimp, ImageMagick, SNAP, Google earth)
4. you also need to have any PDF reader installed in your computer. 

**Installing PolSARpro**
1. Visit the [PolSARpro download page](https://www.ietr.fr/polsarpro-bio/).
2. Download the appropriate version for your operating system.
3. Extract the downloaded files to a directory of your choice.
4. Follow the installation instructions provided in the user manual included in the download.
5. Configure PolSARpro by adding it to your system's PATH environment variable:
   - Navigate to the PolSARpro installation directory and copy three paths typically located in  
   ***a) C:\Program Files (x86)\PolSARpro_v6.0.3_Biomass_Edition\Soft\bin\tools***  
   ***b) C:\Program Files (x86)\PolSARpro_v6.0.3_Biomass_Edition\Soft\bin\bmp_process***  
   ***c) C:\Program Files (x86)\PolSARpro_v6.0.3_Biomass_Edition\Soft\bin\data_process_sngl***  
   - Access system properties by searching for "edit the system variables" and, with administrative privileges, open the Environment Variables panel.
   - In the System Variables section, locate and double-click the "PATH" variable to open the Edit Environment Variable panel.
   - Click "New" and add the three paths copied above. Click "OK" to save the changes.
6. Verify the installation by opening a command line and changing directory to one of the above paths and a sample tool.  
 ***C:\Program Files (x86)\PolSARpro_v6.0.3_Biomass_Edition\Soft\bin\tools>check_binary_data_file.exe***  
  Ensure the command executes without errors.

---

## Step 2: Bulk Download of Sentinel-1 SLC Images

***Python script used to download the images for this test study is available within the 's1_slc_files' folder.***  

Sentinel-1 SLC images were acquired using the Alaska Satellite Facility Data Search platform. To access and download the data, users need an Earth Data account and a username. Bulk download instructions can be found at [ASF Bulk Data Download Options](https://asf.alaska.edu/how-to/data-tools/asf-bulk-data-download-options/). Move all the S1 SLC files to 's1_slc_files' folder for seamless computation.

The imagery collection duration was set from June 10, 2021, to July 30, 2021. Level 1 Single Look Complex (SLC) products were downloaded for the selected area defined by the coordinates (-106.8065, 52.3786, -106.6559, 52.3786, -106.6559, 52.4801, -106.8065, 52.4801, -106.8065, 52.3786). The S1-SLC products were obtained using the on-demand service from the Alaska Satellite Facility Vertex platform. After filtering, a total of 9 images were selected. To easily download the images, download the Python script for bulk download and run it from the command line.

---


## Step 3: SNAP Processing

### Generate the Base Graph (within SNAP)

***Sample base-graph used for this test study provided is available within the 'base_graph' folder.*** 

1. Launch the SNAP software and import a single S1 image (zip file) into its interface.
2. Generate a sample graph with the required processing methods in the proper order:
   - "Read" tool
   - "TOPSAR-Split" tool
   - "Apply-Orbit-File" tool
   - "Calibration" tool
   - "TOPSAR-Deburst" tool
   - "Polarimetric-Speckle-Filter" tool
   - "Terrain-Correction" tool
   - "Write" tool

3. Configure the parameters of each tool according to your specific preferences and requirements.
4. Generate three graphs for each subswath (IW1, IW2, IW3).

### Generate Graphs for Each S1 File (within R)

Generate corresponding SNAP (.xml) graphs for each S1 zip file using the base graph provided. This process results in the creation of 27 SNAP graphs (3 graphs per Sentinel file), representing each combination of the nine zip files and three IW graphs. 

### Batch Processing (within R)

Utilizing the processing capabilities of the computer, batch processing of the graphs can be performed efficiently within R. By assigning an optimal number of cores (e.g., n=5), the library `parallelMap` in R can be employed to concurrently process five graphs in parallel. This approach maximizes computational efficiency and minimizes processing time.

---

## Step 4: PolSARpro Processing (within R)

### Edit config file
The SNAP software generates C2 matrix output in the form of .bin files, essential for PolSARpro processing. The configuration file, `config.txt`, must be edited to replace the parameter "dual" with "pp2" to ensure compatibility with PolSARpro. 

### Move to C2 folder
Generate a C2 folder and move all the processed files from SNAP to the folder.

### Extract Geo Reference Data
The C11.bin file contains the spatial information required for generating the TIFF file (raster). Store this information and generate a reference TIFF file to be later used in generating other parameters.

### Process SAR parameters

#### Extract information from config.txt file  

The config.txt file contains essential metadata crucial for subsequent parameter generation in PolSAR data processing. This metadata, including the number of rows and columns, guides the processing workflow within PolSARpro.

#### Create mask valid pixels 
1. Identify valid mask pixels using the `create_mask_valid_pixels` tool.
2. Create the valid mask based on this pixel information.

#### Create mask BMP file 
1. Create a mask of valid pixels using the 'create_bmp_file' tool. 
2. This BMP file is essential for subsequent processing steps.

#### Process parameters

1. Develop the C11 and C22 elements using the `process_elements` tool.
2. Compute the span using the `process_span` tool.
3. Generate Stokes parameters (g0, g1, g2, g3) and Stokes Angles (orientation angle, ellipticity angle) using the `stokes_parameters` tool.
4. Compute Alpha, Entropy, and Shannon Entropy using the `h_a_alpha_decompositionSPPC2` tool.

### Generate ENVI (.HDR) Files

The .hdr file output from the SNAP process contains the geospatial information for each particular IW swath. Using the `C11.hdr` file, create reference .tif files to preserve the geospatial information.

### Create Raster Files

1. Use the extracted spatial information to create raster files that retain the accurate geospatial information.
2. These raster files will be used as reference points for further processing within PolSARpro to ensure spatial accuracy.

---

## Acknowledgements

The authors would like to acknowledge the invaluable contributions of the open source community, whose efforts and resources have been instrumental in enabling this research.

---

## References

- ARSET. (2022). Mapping Crops and their Biophysical Characteristics with Polarimetric SAR and Optical Remote Sensing. NASA Applied Remote Sensing Training Program (ARSET).  
- ESA. (2023). SNAP - ESA Sentinel Application Platform [Computer Software].  
- Pottier, E., & Ferro-Famil, L. (2012). PolSARPro V5.0: An ESA educational toolbox used for self-education in the field of POLSAR and POL-INSAR data analysis. 2012 IEEE International Geoscience and Remote Sensing Symposium, 7377–7380. https://doi.org/10.1109/IGARSS.2012.6351925 
- RStudio Team. (2024). RStudio: Integrated Development for R. (URL http://www.rstudio.com/). RStudio, PBC.  


---

