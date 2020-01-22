# Nasa2FGearthview
A bash-script to convert NASA satellite images to ready-to-use
textures for FG's EarthView using ImageMagick and normalmap

You can get "normalmap" there:
  https://github.com/eatdust/normalmap

For info about FGearthview, see the forum thread:\
  https://forum.flightgear.org/viewtopic.php?f=6&t=15754

or this FG-wiki-page:\
  http://wiki.flightgear.org/Earthview


> ### Caution!
> Don't use this script on a server! It will most likely cause
> Denial-of-service (DoS). When working on these huge images, the
> harddisk throughput will cease occasionally and CPU / RAM usage will
> spike tremendously! So, only use this script on your home desktop
> computer, or if you don't mind several long server-outages...


------------------------------------
## About:

This script runs on Linux (maybe Mac also?) in a Bash
(Bourne Again Shell) - Windows is not supported (by the nature of the
script). Maybe it works on windows as well, I don't know, feel free
to try, and please let me know! :)

In the end you will have 8 world-textures in .png and .dds format.
Generally .dds is better in performance, but it won't work on some
graphics cards. If this is the case for you, then try the .png files.
For further information see:\
http://wiki.flightgear.org/index.php?title=DDS_Textures_in_FlightGear&redirect=no

If you also converted the clouds and the height maps, then you'll also
find 8 cloud- and 8 height textures (as well as their conversion to
normal maps) in the format .png. Because the .dds-format has trouble
with rendering heavy alpha images, which is because of it's
compression algorythm [1], I think it's useless to also build faulty
files.  However, this is not entirely true! It is possible to switch
off the .dds/DXT compression. But this results in huge files and is
rather heavy on the GPU's RAM.

Buckaroo has created a nice overview on dds-compression:
[1] http://www.buckarooshangar.com/flightgear/tut_dds.html

------------------------------------
## Installation and usage:

Simply copy "convert.sh" into a folder of your liking and run it:

```shell
./convert.sh
```

This will show a help text, since you didn't specify any target(s).
Possible targets are:
* world
* clouds
* heights
* all

Additionally, there are some options you could specify (further
explained below):
* 1k | 2k | 4k | 8k | 16k
* download | no-download
* world
* clouds
* heights
* cleanup
* rebuild
* check

So your call could look sth like this:

```shell
./convert.sh world download alt cleanup 8k
```


------------------------------------
## Requirements:

> WARNING!
>
> This script uses a *lot* disk space! In my last test run, which
> generated all maps in all resolutions, the disk usage was about 330GB!
> Beware!\
> Also, I wouldn't recommend doing this on a SSD! While SSDs are
> generally faster, they also get more wear-and-tear when write such
> huge files. So this script might cause your SSD to die earlier as it
> should. Generally speaking, this won't kill your SSD, but it might
> cause it to die earlier. HDDs are much more robust in that respect.
>
> Also, this script will run for a *very long* time! It might be best to
> let it run over night - your computer might become unresponsive from
> time to time, due to the heavy CPU and memory load, which tends to
> occur, when converting 54000x27000 images. ;-)

I also recommend to deactivate swapping!
```shell
  sudo swapoff -a
 ```
To reactivate swapping do:
```shell
  $ sudo swapon -a
```

This script relies on wget, ImageMagick and, for converting the height
maps to normal maps, on "normalmap". Some of these programs are easily
installed by your systems package-management-system.\ (On
Debian/Ubuntu this is "apt-get").

So, on Debian for instance, you only need to put the following into
the console:

```shell
sudo apt-get install wget imagemagick
```

Depending on your distro, the package names might differ slightly! Use
a search engine of your choice to find out, how the packages are named
in your distro!

You may want to check:

```shell
apt search imagemagick
```

### IMPORTANT!
Check out your ```/etc/ImageMagick-7/policy.xml```
On some distros, there are limits set, which will cause IM to abort
the conversion of images larger than
[ridiculously small images](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=860763).
Edit and set to our needs:
* width: at least 55000
* height: at least 55000
* area: less than your free RAM

### Normalmap
For normalmap, you can download and compile it from
  https://github.com/planrich/normalmap

You can install the binary into your system, or just copy it next to
convert.sh - both should work.

------------------------------------
## Targets:

**world**\
        Generates the world tiles, needed to run FG with EarthView.
        You will find the results in output/[$resolution]/\*. Copy
        these into $FGDATA/Models/Astro/\*. More about the installation
        of these textures can be found here:
        http://wiki.flightgear.org/Earthview#Customization

**clouds**\
        Generates the cloud tiles, needed to run FG with EarthView.
        The locations are the same as the other textures mentioned
        above. Note that clouds are only available with up to 8k
        resolution, due to the available data at NASA.

**heights**\
        Generates the height tiles, which are then converted to the
        normal maps needed to run FG with EarthView. The locations are
        the same as the other textures mentioned above. Note that
        heights are only available with up to 8k resolution, due to the
        available data at NASA.

**all**\
        Converts everything needed for a full-blown earthview texture
        set. Does the same as:
        ```./convert.sh world clouds heights```


## Options:

**1k | 2k | 4k | 8k | 16k**\
        Lets you specify a desired resolution of the textures.
        Possible values are 1k, 2k, 4k, 8k and 16k. If nothing is
        specified, the script will generate all of the resolutions.
        16k is recommended only for earth textures, it will induce
        oversampling from clouds and height maps.

**download**\
        Causes the script to download the needed data, this is the
        default behavior (and can be omitted).

**no-download**\
        Causes the script to skip the download function. If you
        already have the source images, then you don't need to
        re-download them. (About 2.4GB!)
        If omitted, the script will download the source images from
        the default location.

**cleanup**\
        Deletes the temporary files created during texture generation.
        These can be found in tmp/
        Note: if for some reason you later want some other resolution,
        then it's good to have the data there. So only do this, when
        you're quite sure that you're done.
        Frees up a lot of disk-space! Which would have to be
        regenerated if needed again.

**rebuild**\
        Deletes only the temporary files of the given target. So if
        you call ```./convert.sh rebuild world``` the script will delete
        all corresponding temp-files of the target world, which will
        trigger a complete regeneration of the relevant (instead of
        skipping existing files)

**check**\
        Creates mosaics of the tiles, so you can look at them and see
        if all went well.
