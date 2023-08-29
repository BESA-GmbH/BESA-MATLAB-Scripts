[![BESA logo](https://www.besa.de/wp-content/uploads/2014/05/pre_logo.jpeg)](https://www.besa.de/)

# BESA Connectivity Scripts

The functions in this directory are maintained by the BESA developers. In case of questions or support requests please fill in our web-based form at [BESA Support](https://www.besa.de/support/support-page/)

## Purpose

### From MATLAB to BESA Connectivity

* [Matlab_to_BESAConnectivity.m](./Matlab_to_BESAConnectivity.m)

This script can be used as an example to generate and export data from MATLAB to BESA Connectivity. It shows how to define required parameters, generates example sine waves and calls the export function [besa_save2Connectivity.m](../../MATLAB2BESA/besa_save2Connectivity.m) to store the simulated example data to disc. It will store the file containing the binary data matrix, as well as the header file and channel description file in ASCII format.

The script can be easily adopted to export your trial data do BESA Connectivity for time-frequency and connectivity analysis! 

For more information on this topic please visit the following site in our Wiki: [How to Prepare Data for BESA Connectivity](http://wiki.besa.de/index.php?title=How_to_Prepare_Data_for_BESA_Connectivity).

* [Analyzer_to_BESAConnectivity.m](./Analyzer_to_BESAConnectivity.m)

This script can be used as an example to export BrainVision Analyzer data from MATLAB to BESA Connectivity. It is based on the MATLAB script `Matlab_to_BESAConnectivity.m` mentioend above.

### From BESA Connectivity to BESA Statistics

* [BESA_Connectivity_to_BESA_Statistics.m](./BESA_Connectivity_to_BESA_Statistics.m)

In order to be able to import connectivity matrices into BESA Statistics 2.0, it is necessary to convert `.conn` files exported from BESA Connectivity to `.tfc` files which can be read by BESA Statistics. This script will perform the required conversion.
   
Also see our Wiki page [How to Convert BESA Connectivity results for BESA Statistics](http://wiki.besa.de/index.php?title=How_to_Convert_BESA_Connectivity_results_for_BESA_Statistics) for more details.
