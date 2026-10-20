---
title: "InaSAFE 3.2.5 is released!"
date: "2016-01-11"
author: "Tim Sutton"
---
# InaSAFE 3.2.5 is released!

This is another bug fix release which fixes issues with the wizard and pdf generator and provides a number of other small enhancements:

- Adds data source and CRS to the keywords list in dock

- Wizard: ged rid of eval() statements [#2329](https://github.com/inasafe/inasafe/issues/2329)

- Use Date Picker in Keywords Wizard [#2499](https://github.com/inasafe/inasafe/issues/2499)

- Fix Keywords Wizard crashes on repeated use [#2514](https://github.com/inasafe/inasafe/issues/2514)

- Fix Crash Minidump when try to use InaSAFE keyword editor twice [#2467](https://github.com/inasafe/inasafe/issues/2467)

- Fix [#2515](https://github.com/inasafe/inasafe/issues/2515) BUG : Can Not Use the Wizard (because No module named qgsdatetimeedit)

- Fix serializing classified raster values

- Fix [#2504](https://github.com/inasafe/inasafe/issues/2504) – exception raised when messaging cell contains nested table or bullet list due to slashes param not being accepted by table class to_html() method.

- Fix Python error in PDF generator and Open in Composer using IFCW [#2532](https://github.com/inasafe/inasafe/issues/2532)

- Fix Python bug when creating a pdf map [#2523](https://github.com/inasafe/inasafe/issues/2523)

 

Windows users can directly download and install using [this installer](https://github.com/inasafe/inasafe/releases/tag/version-3_2_5). Users on other platforms and windows users who prefer to use the plugin manager can install the updated plugin using the QGIS plugin manager.
