---
title: "InaSAFE 4.0 is released!"
date: "2017-03-22"
author: "Tim Sutton"
---
# InaSAFE 4.0 is released!

Version 4.0.0 brings with it the following changes:
– Complete overhaul of the InaSAFE code base
– Deprecated numpy / matrix based geometry manipulation
– New reporting system including Jinja2 support
– Experimental support for Infographics
– Removed all impact functions in favour of a shared workflow for all hazards
– Added support for exposure specfic thresholds in hazard metadata
– Produce rich data outputs instead of simple HTML reports
– Added new hazard support for Tropical Cyclone
– Extensive updates to the help reference and a new help browser
– Removal of all logic that uses interpolation to assess impact level
– Application of standards to reporting and calculations for more consistent presentation
– Ability to work with larger datasets in many cases (just be patient while analysis runs)
– Speed ups and improvements to many parts of the code base
– Improvements to the batch runner tool
– Improvements to the shake grid importer tool
– Port of the minimum needs tool to use our new architecture
– Added support for analysis of irregular areas (as defined by aggregation layer)
– Features or population outside of aggregation areas are no longer counted as part of the total exposure count
– Added support for working with data subsets
– Analysis no longer works only with local file sources
– All geometry operations are performed using the QGIS API now
– QGIS layers list items now have a context menu for InaSAFE
– Input layers no longer need to be in EPSG:4326
– Moved realtime code to its own repository
– Improved error handling system
– Added profiling for all analysis steps so we can easily identify performance bottlenecks
– Improved how partial overlaps with a hazard are managed (feature is assigned highest impact zone)
– Generate rich provenance for use in reporting
– Generate multiple sub products (impact layer, aggregation by hazard layer)
– PDF Reports are generated directly once analysis completes
– Earthquake sub-algorithm selection has been moved to the InaSAFE options dialog
– ITB Bayesian algorithm is now default for earthquake
– Earthquake analysis map output is now a boolean layer indicating if a cell contains displaced people
– Many, many more improvements…

 

For a visual guide showing some of the key features, please visit the [InaSAFE 4.0.0 Visual Changelog](https://changelog.inasafe.org/en/inasafe/version/4.0.0/)

**Special Note:**

Please note that when migrating from InaSAFE 3.x to version 4, you need to update the metadata ‘keywords’ for any layer you have previously defined keywords for.
