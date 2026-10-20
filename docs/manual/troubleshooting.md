

# Troubleshooting


## Network Timeout


One of the most common problems with installing InaSAFE is,
due to the large paket size of InaSAFE the downloading in slow(er)
internet connections.
If you frequently receive a timeout of your netwerk connection try to set
**Settings > Options > Network > Timeout for network requests**
to a higher number.

If you have no permanent network connection or you want to pass
InaSAFE to friend who do now have an internet connection you can also
install InaSAFE by manually downloading it from
http://planet.qgis.org/plugins/inasafe/ by clicking on the latest version and
then choose **Download**.
This will get you the `inasafe-x.x.x.zip` file which you can afterwards
extract in the plugins path of your QGIS installation.

If you have a copy of the plugin code in a zip file,
you can install it unzipping it into the QGIS plugins folder.
In Windows, it should be something like
C:\\Users\\<your_user>\\.qgis2\\python\\plugins.
In Linux/Mac, it should be in ~/.qgis2/python/plugins.
Copy the inasafe folder in your zip file into your plugins folder.
You should end up having a .qgis2\python\plugins\inasafe folder with the code
of the plugin and the required subfolders.


If your problems are still not solved you can write an email to
info@inasafe.org.
We also have a InaSAFE User Mailinglist where you are very welcome to
join and ask your questions there.
More information about howto join the list is available on getting_help.
