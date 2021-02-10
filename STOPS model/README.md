# STOPS Model for Honolulu

The Simplified Trips-on-Project (STOPS) model is a simplified transit ridership forecasting modeling system developed by the Federal Transit Administration. It includes the elements of traditional trip-based modeling approach, with an emphasis on robust mode choice analyses. The STOPS system is typically used to evaluate projects seeking funding from FTA's [Capital Investment Grants Program](https://www.transit.dot.gov/CIG). An earlier version of STOPS was used to develop ridership projects for the [Honolulu Rail Project](https://www.honolulutransit.org/) and in FTA STOPS training workshops. The model was updated by Julie Dunbar and Bill Davidson in 2020 to support on-going travel forecasting work by the OahuMPO. In the near term the results will be used to validate the existing Version 6 of the regional travel model. In the longer term is will also be compared to, and possibly a part of, the planned Version 7 system.

Several scenarios were built as part of PAO 6, Transit Model Evaluation and Improvement, in the FY20-21 OahuMPO travel modeling support contract. Each scenario includes a data for a specific year and transit network. Different scenarios can be constructed for different time horizons, different project alignments, or different socioeconomic inputs to the model. All three scenarios were constructed using 2015 socioeconomic data and highway congestion measures (skims). The three scenarios differ in their assumed transit network and service levels:

+ A [2017 base year](https://www.dropbox.com/s/axe8iq14103jred/honolulu2017.zip) that ...
+ A [2019 base year](https://www.dropbox.com/s/h3c336m7ijpyg4w/honolulu2019.zip) that ...
+ A [19BLDNR](https://www.dropbox.com/s/3tp3nkasqu5zk52/honolulu19BLDNR.zip) scenario includes ...

Each link above is associated with a compressed archive file approximately 500 MB in size. It contains all of the input and output files associated with that scenario. A control file for running the program is included in the top-level directory of each of the compressed archives. The folders included in each scenario are defined by the STOPS program, with the `Inputs` and `Districts` folders being created for each scenario and the remainder created by STOPS to hold intermediate working or output files:

+ `Districts`
+ `GTFOutput`
+ `Inputs` contains required input files to run the scenario.
+ `Logfiles`
+ `OutputData`
+ `Reports`
+ `Scratch`
+ `Skims`
+ `Stops`

STOPS version 2.5 was used to run these scenarios. An installer and draft user guide are stored in the `software` folder in this repository. This is a newer version of the software than available for public download on the [STOPS software webpage](https://www.transit.dot.gov/funding/grant-programs/capital-investments/stops).

Potential STOPS users are expected to be experienced in travel demand forecasting, particularly mode choice and transit network modeling. A one-day workshop was conducted on December 14, 2020 to explain how STOPS was implemented in Honolulu. The presentation materials are stored in the `training` folder, and a videorecording of the session is [available for download](https://www.dropbox.com/s/ls9g1ogyh7fry5a/OahuMPO%20STOPS%20training-14Dec20.mp4).  It was not designed to be a replacement for the three-day [FTA STOPS course](https://www.ntionline.com/rideship-forecasting-with-stops-for-transit-project-planning/), which is offered on an infrequent basis. A [STOPS application guidebook](https://www.fsutmsonline.net/images/uploads/Task_1_Guidebook_for_Florida_STOPS_Application.pdf) from the Florida DOT provides an overview that complements the user guide included in the `training` folder.
