# Cell Proliferation Assay

## Description

Pulse-chase experiments using 5-bromo-2'-deoxyuridine (BrdU), or the more recent EdU (5-etynil-2'-deoxyuridine), enable the identification of cells going through S phase. Furthermore, these DNA synthesis-based methods can be combined with the detection of proliferation-specific proteins to estimate the percentage of cells in other cell cycle phases, thus obtaining a more detailed analysis of the culture proliferation. One of the most commonly used markers is Ki67, which is present within the nucleus of cycling cells during G1, S, G2, and M phases, but not during quiescence (G0). Additionally, phosphohistone 3 (PHH3) can be used to identify those cells that are specifically undergoing mitosis (M phase). By combining a short nucleoside analogue pulse (S phase) with immunocytochemical
detection of Ki67 (cycling cells) and PHH3 (M phase), the entire range of cell cycle phases in the sample can be determined. Alternatively, nucleoside pulse-chase may be combined with the detection of other nuclear markers, e.g., antigens associated to specific subpopulations present in the culture, which would allow to estimate the proliferation (S phase) rate of each individual subpopulation.

Our main goal here was to develop a protocol for non-supervised, high throughput image analysis of _ex vivo_ cell proliferation assays based on nucleoside analogue pulse alone or in combination with other nuclear markers. Our assay has been deplyed to be imaged using the high content microscope IN Cell Analyzer 2000 (GE Healthcare), so the script takes as imput datasets acquired using this and other IN Cell Analyzer versions. It consists of an ImageJ macroinstruction which can be easily added and kept to date using the Fiji distribution of ImageJ, as explained above. The workflow segments the individual nuclei and measures the signal of up to three nuclear markers.  Moreover, the results table include measurements for post-processing image- and object-quality assessment. The assay must include at least two channels per field-of-view: i) on one hand, the counterstain channel to segment the nuclei; ii) on the other hand, the nucleoside analogue channel to measure the signal of each nucleus.

Please note that the (optional) illumination correction step included in the workflow requires to load a correction function. In the **Usage** section of this README you will find useful information to this aim.

In order to assess the output of the assay it is advisable to use a different software suited to explore high content microscopy data, such as [shinyHTM](https://github.com/embl-cba/shinyHTM/blob/master/README.md#shinyhtm).

**Please note that the Cell Proliferation script is based on a publication. The original version is the Cell ProliferationHTS script (outdated). How to cite Cell Proliferation in publications:**

* Carrillo-Barberà P., Morante-Redolat J.M., Pertusa J.F. (2019) "[Cell Proliferation High-Content Screening on Adherent Cell Cultures](https://doi.org/10.1007/978-1-4939-9686-5_14)". In: Rebollo E., Bosch M. (eds) Computer Optimized Microscopy. Methods in Molecular Biology, vol 2040. Humana, New York, NY. DOI: https://doi.org/10.1007/978-1-4939-9686-5_14

## Requirements

* [Fiji](https://fiji.sc/)
* Image dataset following an IN Cell Analyzer file naming convention (note that the NeuroMol update site includes a [macroinstruction](https://github.com/paucabar/other_macros) to turn data acquired with diferent high content microscopes into an IN Cell Analyzer file naming convention dataset)

## Installation

1. Start [FIJI](https://fiji.sc/)
2. Start the **ImageJ Updater** (<code>Help > Update...</code>)
3. Click on <code>Manage update sites</code>
4. Click on <code>Add update site</code>
5. A new blank row is to be created at the bottom of the update sites list
6. Type **NeuroMol Lab** in the **Name** column
7. Type **http://sites.imagej.net/Paucabar/** in the **URL** column
8. <code>Close</code> the update sites window
9. <code>Apply changes</code>
10. Restart FIJI
11. Check if <code>NeuroMol Lab</code> appears now in the <code>Plugins</code> dropdown menu (note that it will be placed at the bottom of the dropdown menu)

## Test Dataset

Download an example [image dataset](https://drive.google.com/drive/folders/1TpVaDCsidEvTLiANmfiKwsXUWDTw9Xes?usp=sharing). Please note that the dataset also includes a subfolder containing correction functions, for the illumination correction of each channel, and a pre-established set of parameters.

**Brief description of the dataset:**
The example datset consists in a cell proliferation and apoptosis assay, parameters routinely assessed. The dataset was generated using methods widely used in fields such as cancer drug discovery: i) EdU (5-etynil-20-deoxyuridine) pulse-chase to label the genomic DNA of cells undergoing S-phase and ii) caspase3 immunocytochemistry. The dataset was acquired within 4 different channels: i) DAPI for counterstain, ii) Cy3 for EdU, iii) FITC for caspase3 and iv) brightfield.

## Usage

### Pre-analysis mode

1. Run the **Cell proliferationHCS** macro (<code>Plugins > NeuroMol Lab > Cell Proliferation > Cell proliferation</code>)
2. Select the directory containing the images (.tif files)
3. Select the type of **Project** to be applied. *Filtering* and *StarDist* are different templete workflows for segmentation. *Filtering* is a faster, filter-based approach, whiche requires more parameters to set and is more propense to merge and split objects. *StarDist* is a deep-learning approach which uses the *Versatile (fluorescent nuclei)* pre-trained model of this Fiji plugin. *StarDist* is slower but can perform a much more accurate segmentation if the dataset is reasonably similar to the pre-trained one (object size may be crucial). It is also possible to *Load* a pre-stablished set of parameters
4. Check **Load function** to perform illumination correction based on reference images
5. Note that **Save ROIs** only works within the **Analysis mode**
6. Ok
7. If **Load function** is checked, a window will prompt to browse the folder containing the reference image(s)
8. If the **Load** option (**Project**) is checked, a window will prompt to browse the corresponding file
9. Adjust the parameters. Know more about the parameters of the workflow on the **wiki page (not yet)**
10. Ok
11. Select the wells to be pre-analysed
12. Select the number of random images that you want to test per well (up to 10 if the number of fields-of-view is greater than that number)
13. Select a feature to classify the objects (e.g., area, mean gray value, integrated density, circularity, aspect ratio, solidity...). Please note that this parameter (and the two below) will not afect the segmentation, only the visualization of the segmentation (_see Figure 1_)
14. Select a threshold to split the objects according to the selected feature. Segmented objects will be outlined according to the selected feature and its threshold (_see Figure 1_)
15. Set the line width of the segmentation outline
16. Ok
17. Once the pre-analysis is finished, a stack containing the images for visualization will pop-up

![image](https://user-images.githubusercontent.com/39589980/81289441-b969bd00-9066-11ea-85df-96e7a98be6ce.png)

**Figure 1.** _Pre-analysis mode_ output. The macro generates a stack. Each image shows the merge of the counterstain (blue) and the nucleoside analogue (red) channels. Additionally, outlines represent the segmentation output of nuclei with different colours, depending on the classification output. Objects with feature values less than or equal to the established threshold are outlined in cyan. Conversely, objects with feature values greater the established threshold are outlined in orange. **A)** Visualization of the mean gray value split at 250 (a.u.). **B)** Visualization of the solidity split at 0.9. **a.u.:** arbitrary unit.

### Analysis mode

1. Run the **Cell proliferationHCS** macro (<code>Plugins > NeuroMol Lab > Cell Proliferation > Cell proliferation</code>)
2. Select the directory containing the images (.tif files)
3. Check **Load project** to use a pre-stablished set of parameters
4. Check **Load function** to perform illumination correction based on reference images
5. Check **Save ROIs** to save the nuclei ROIs
6. Ok
7. If **Load function** is checked, a window will prompt to browse the folder containing the reference image(s)
8. If **Load project** is checked, a window will prompt to browse the corresponding file
9. Adjust the parameters. Know more about the parameters of the workflow on the **wiki page (not yet)**
10. Ok
11. Select the wells to be analysed
12. Ok
13. A series of new files will be saved within the selected directory: a parameters set file (.txt), a results table file (.csv), a quality control (QC) metrics file (.csv) and, if checked, the ROI  files (.zip)

## Contributors

[Pau Carrillo-Barberà](https://github.com/paucabar)

## License

Cell Proliferation in licensed under [MIT](https://imagej.net/MIT)
