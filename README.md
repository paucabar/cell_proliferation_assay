# Cell Proliferation Assay

## Description

Pulse-chase experiments using 5-bromo-2'-deoxyuridine (BrdU), or the more recent EdU (5-etynil-2'-deoxyuridine), enable the identification of cells going through S phase. This chapter describes a high-content proliferation assay pipeline for adherent cell cultures. High-throughput imaging is followed by high-content data analysis using a non-supervised ImageJ macroinstruction that segments the individual nuclei, determines the nucleoside analogue absence/presence, and measures the signal of up to two additional nuclear markers. Based upon the specific combination with proliferation-specific protein immunostaining, the percentage of cells undergoing different phases of the cell cycle (G0, G1, S, G2, and M) might be established. The method can be also used to estimate the proliferation (S phase) rate of particular cell subpopulations identified through labelling with specific nuclear markers.

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

Download an example [image dataset](https://drive.google.com/drive/folders/1jwnGSs7girbFtYbgd5Bqg1KrctMR7iJa?usp=sharing).

## Usage

### Illumination correction (recommended)

soon

### Pre-analysis mode

1. Run the **Cell proliferationHCS** macro (<code>Plugins > NeuroMol Lab > Cell Proliferation > Cell proliferationHCS</code>)
2. Select the directory containing the images (.tif files)
3. Check **Load project** to use a pre-stablished parameter dataset
4. Ignore the **Save ROIs** option
5. Ok
6. Adjust the parameters. Know more about the parameters of the workflow on the **wiki page (not yet)**
7. Ok
8. Select an image (well and field-of-view) to test the parameters
9. Check the output (_see Figure 1_)
10. **Pre-analysis mode** will ask to test a new image, and will continue until the user asks to stop

![image](https://user-images.githubusercontent.com/39589980/79926791-18f88380-843e-11ea-9373-e8acf37ecfe1.png)

**Figure 1.** _Pre-analysis mode_ output. The macro generates a stack composed of two images. On one hand, the merge of the counterstain (blue) and the cell tracker (red) (**left**). On the other hand, the merge of the counterstain (gray), the additionally segmented monolayer (green) and the remaining background (blue) (**right**). Finally, when detected, ROI Manager will store the ROI set of tracker-labeled cells, shown as a yellow, numbered outline (**left**)

### Analysis mode

1. Run the **Cell proliferationHCS** macro (<code>Plugins > NeuroMol Lab > Cell Proliferation > Cell proliferationHCS</code>)
2. Select the directory containing the images (.tif files)
3. Check **Load project** to use a pre-stablished parameter dataset
4. Check **Save ROIs** to store the regions of interest of the counted cells
5. Ok
6. Adjust the parameters. Know more about the parameters of the workflow on the **wiki page (not yet)**
7. Run
8. A series of new files will be saved within the selected directory: a parameter (.txt) file, a results table (.csv) file and the ROI (.zip) files (if checked)

## Contributors

[Pau Carrillo-Barberà](https://github.com/paucabar)

## License

Cell Proliferation in licensed under [MIT](https://imagej.net/MIT)
