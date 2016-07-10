# Nasa2FGearthview
A bash-script to convert NASA satellite images to ready-to-use
textures for FG's EarthView using ImageMagick.


------------------------------------
About:

This script runs on Linux (maybe Mac also?) in a Bash
(Bourne Again Shell) - Windows is not supported (by the nature of the
script). Maybe it works on windows as well, I don't know, feel free
to try, and please let me know! :)

This will download the raw images from http://visibleearth.nasa.gov - 
their server is not very fast, so I provide an alternative download
location: https://musicchris.de/download/FG/EarthView/raw-data-NASA.7z
This one is much quicker! If you really want the images directly from
NASA, then provide "nasa" to the script (see below)

In the end you will have 8 world-textures in .png and .dds format.
Generally .dds is better in performance, but it won't work on some
graphics cards. If this is the case for you, then try the .png files.

If you also converted the clouds, then you'll also find 8 cloud-
textures in the format .png. Because the .dds-format has trouble with
rendering heavy alpha images, which is because of it's compression
algorythm, I think it's useless to also build faulty files.
However, this is not entirely true! It is possible to switch off the
.dds/DXT compression. But this results in huge files and is rather
heavy on the GPU's RAM.


------------------------------------
Installation and usage:

Simply copy "convert.sh" into a folder of your liking and run it:

$ ./convert.sh

This will show a help text, since you didn't specify any target(s).
Possible targets are:
* world
* clouds

Additionally, there are some options you could specify (further
explained below):
* 1k | 2k | 4k | 8k | 16k
* nasa
* no-download
* cleanup
* rebuild
* check

So your call could look sth like this:

$ ./convert.sh world no-download cleanup 8k


------------------------------------
Requirements:

WARNING!

This script uses a *lot* disk space! Make sure you have at least 90GB
available!

Also, this script will run for a *very long* time! It might be best to
let it run over night - your computer might become unresponsive from
time to time, due to the heavy CPU and memory load, which tends to
occur, when converting 54000x27000 images. ;-)

This script relies on wget and imagemagick. Both are easily installed
by your systems package-management-system.
(On Debian/Ubuntu this is "apt-get")

So, on Debian for instance, you only need to put the following into
the console:

$ sudo apt-get install wget imagemagick

Depending on your distro, the package names might differ slightly! Use
a search engine of your choice to find out, how the packages are named
in your distro!


------------------------------------
Options:

*world*<br>
	Generates the world tiles, needed to run FG with EarthView.
	You will find the results in output/[$resolution]/*. Copy
	these into $FGDATA/Models/Astro/*. More about the installation
	of these textures can be found here:
	http://wiki.flightgear.org/Earthview#Customization

*clouds*<br>
	Generates the cloud tiles, needed to run FG with EarthView.
	The locations are the same as the other textures mentioned
	above. Note that clouds are only available with up to 8k
	resolution, due to the available data at NASA.

*resolution*<br>
	Lets you specify a desired resolution of the textures.
	Possible values are 1k, 2k, 4k, 8k and 16k. If nothing is
	specified, the script will generate all of the 5 resolutions.

*nasa*<br>
	Causes the script to download directly from 
	http://visibleearth.nasa.gov . If omitted the script will
	download from
	https://musicchris.de/download/FG/EarthView/raw-data-NASA.7z
	which is much faster!

*no-download*<br>
	Causes the script to skip the download function. If you
	already have the source images, then you don't need to
	re-download them. (About 2.4GB!)
	If omitted, the script will download the source images from
	NASA. ( http://visibleearth.nasa.gov/ )
	Uses wget.

*cleanup*<br>
	Deletes the temporary files created during texture generation.
	These can be found in tmp/
	Note: if for some reason you later want some other resolution,
	then it's good to have the data there. So only do this, when
	you're quite sure that you're done.

*rebuild*<br>
	Deletes only the temporary files of the given target. So if
	you call './convert.sh rebuild world' the script will delete
	all corresponding temp-files of the target world, which will
	trigger a complete regeneration (instead of skipping existing
	files)

*check*<br>
	Creates mosaics of the tiles, so you can look at them and see
	if all went well.
