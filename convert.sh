#!/bin/bash

VERSION="v0.01"

# make sure the script halts on error
set -e

function showHelp
  {
   echo "Nasa2FGearthview converter script $VERSION"
   echo "https://github.com/chris-blues/Nasa2FGearthview"
   echo
   echo "Usage:"
   echo "./convert.sh [ download world clouds 8k no-cleanup continue ]"
   echo
   echo "* Append \"download\" to download the needed images from NASA"
   echo "  -> This will download ca 2.4GB of data!"
   echo "  -> wget can continue interrupted downloads!"
   echo "* Append \"world\" to the command to generate the world tiles"
   echo "* Append \"clouds\" to the command to generate cloud tiles"
   echo "* Append the size of the tiles (1k, 2k, 4, 8k). If you don't"
   echo "  pass a resolution, then all resolutions will be generated."
   echo "* Append \"no-cleanup\" to keep the temporary image files in"
   echo "  tmp/"
   echo "* Append \"continue\" to the command to continue a previously"
   echo "  failed run"
   echo
   echo "WARNING!"
   echo "This script uses a _lot_ of disk space! Make sure you choose"
   echo "a disk, with at least 70GB free space."
   echo
   echo "This script will take a very long time, depending on your CPU"
   echo "and memory. It's propably best, to let it run over night..."
   echo
   exit 1
  }
if [ -z $1 ] ; then showHelp ; fi
if [ $1 == "--help" ] ; then showHelp ; fi
if [ $1 == "-h" ] ; then showHelp ; fi

################################
## Get command line arguments ##
################################
for ARG in "$@"
do
  if [ $ARG == "download" ] ; then DOWNLOAD="true" ; echo "Downloading images from nasa.gov" ; fi
  if [ $ARG == "world" ] ; then WORLD="true" ; echo "Generate world textures" ; fi
  if [ $ARG == "clouds" ] ; then CLOUDS="true" ; echo "Generate cloud textures" ; fi
  if [ $ARG == "1k" ] ; then RESOLUTION="1024" ; fi
  if [ $ARG == "2k" ] ; then RESOLUTION="2048" ; fi
  if [ $ARG == "4k" ] ; then RESOLUTION="4096" ; fi
  if [ $ARG == "8k" ] ; then RESOLUTION="8192" ; fi
  if [ $ARG == "no-cleanup" ] ; then CLEANUP="false" ; fi
  if [ $ARG == "cleanup" ] ; then CLEANUP="true" ; fi
  if [ $ARG == "continue" ] ; then CONTINUE="true" ; echo "Will continue previous run" ; fi
done
if [ -z $DOWNLOAD ] ; then DOWNLOAD="false" ; fi
if [ -z $WORLD ] ; then WORLD="false" ; fi
if [ -z $CLOUDS ] ; then CLOUDS="false" ; fi
if [ -z $CLEANUP ] ; then CLEANUP="true" ; fi
if [ -z $CONTINUE ] ; then CONTINUE="false" ; fi

if [ $CLEANUP == "true" ] ; then echo "Will delete temporary files after this run" ; fi
if [ $CLEANUP == "false" ] ; then echo "Will keep temporary files after this run" ; fi


########################
## Set some variables ##
########################
URLS_WORLD="http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.A1.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.A2.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.B1.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.B2.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.C1.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.C2.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.D1.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/74000/74117/world.200408.3x21600x21600.D2.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/79000/79765/dnb_land_ocean_ice.2012.54000x27000_geo.tif"

URLS_CLOUDS="http://eoimages.gsfc.nasa.gov/images/imagerecords/57000/57747/cloud.E.2001210.21600x21600.png
http://eoimages.gsfc.nasa.gov/images/imagerecords/57000/57747/cloud.W.2001210.21600x21600.png"


if [ -z $RESOLUTION ]
  then 
    RESOLUTION="1024
2048
4096
8192"
fi
echo "Building resolution: $RESOLUTION"

NASA="A1
B1
C1
D1
A2
B2
C2
D2"

IM="0
1
2
3
4
5
6
7"

TILES="N1
N2
N3
N4
S1
S2
S3
S4"

BORDERS="top
right
bottom
left"

CROP_TOP="8064x1+64+64"
CROP_RIGHT="1x8064+8127+64"
CROP_BOTTOM="8064x1+64+8127"
CROP_LEFT="1x8064+64+64"
CROP_TOPLEFT="1x1+64+64"
CROP_TOPRIGHT="1x1+8127+64"
CROP_BOTTOMRIGHT="1x1+8127+8127"
CROP_BOTTOMLEFT="1x1+64+8127"


## HORIZ meaning a horizontal bar, like the one on top
HORIZ_RESIZE="8064x64"
VERT_RESIZE="64x8064"

POS_TOP="+64+0"
POS_RIGHT="+8128+64"
POS_BOTTOM="+64+8128"
POS_LEFT="+0+64"


#################
##  FUNCTIONS  ##
#################

function NasaToFG
  {
   if [ $1 == "A1" ] ; then DEST="N1" ; fi
   if [ $1 == "B1" ] ; then DEST="N2" ; fi
   if [ $1 == "C1" ] ; then DEST="N3" ; fi
   if [ $1 == "D1" ] ; then DEST="N4" ; fi
   if [ $1 == "A2" ] ; then DEST="S1" ; fi
   if [ $1 == "B2" ] ; then DEST="S2" ; fi
   if [ $1 == "C2" ] ; then DEST="S3" ; fi
   if [ $1 == "D2" ] ; then DEST="S4" ; fi
   echo "$1 -> $DEST"
  }

function IM2FG
  {
   if [ $1 == "0" ] ; then DEST="N1" ; fi
   if [ $1 == "1" ] ; then DEST="N2" ; fi
   if [ $1 == "2" ] ; then DEST="N3" ; fi
   if [ $1 == "3" ] ; then DEST="N4" ; fi
   if [ $1 == "4" ] ; then DEST="S1" ; fi
   if [ $1 == "5" ] ; then DEST="S2" ; fi
   if [ $1 == "6" ] ; then DEST="S3" ; fi
   if [ $1 == "7" ] ; then DEST="S4" ; fi
  }

function downloadImages
  {
   if [ $WORLD == "true" ] ; then downloadWorld ; fi
   if [ $CLOUDS == "true" ] ; then downloadClouds ; fi
  }

function downloadWorld
  {
   mkdir -p input

   for f in $URLS_WORLD
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     wget --output-document=input/$FILENAME --continue --show-progress $f
   done
  }

function downloadClouds
  {
   mkdir -p input

   for f in $URLS_CLOUDS
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     wget --output-document=input/$FILENAME --continue --show-progress $f
   done
  }

function generateWorld
  {
   echo
   echo "################################"
   echo "####    Processing World    ####"
   echo "################################"
   echo

   mkdir -p tmp
   mkdir -p output

   ############################
   ##  Prepare night lights  ##
   ############################

   ########################################
   ## Convert to a more efficient format ##
   ########################################
   if [ ! -s "tmp/nightlights_54000x27000.mpc" ]
   then
     env MAGICK_TMPDIR=${PWD}/tmp nice -10 convert -monitor -limit memory 32 -limit map 32 input/dnb_land_ocean_ice.2012.54000x27000_geo.tif tmp/nightlights_54000x27000.mpc
   else echo "=> Skipping existing file: tmp/nightlights_54000x27000.mpc"
   fi

   ########################
   ## Resize nightlights ##
   ########################
   if [ ! -s "tmp/nightlights_32256x16128.mpc" ]
   then
     env MAGICK_TMPDIR=${PWD}/tmp nice -10 convert -monitor -limit memory 32 -limit map 32 tmp/nightlights_54000x27000.mpc -resize 32256x16128 tmp/nightlights_32256x16128.mpc
   else echo "=> Skipping existing file: tmp/nightlights_32256x16128.mpc"
   fi

   ##########################################
   ## Extract low colors (Continents, ice) ##
   ##########################################
   if [ ! -s "tmp/nightlights_32256x16128_lowColorsCut.mpc" ]
   then
     env MAGICK_TMPDIR=${PWD}/tmp nice -10 convert -monitor -limit memory 32 -limit map 32 tmp/nightlights_32256x16128.mpc -channel R -level 7.8%,100%,1.5 -channel G -level 13.7%,100%,1.5 -channel B -level 33%,100%,1.5 +channel tmp/nightlights_32256x16128_lowColorsCut.mpc
   else echo "=> Skipping existing file: tmp/nightlights_32256x16128_lowColorsCut.mpc"
   fi

   ############################
   ## Make sure, we're using grayscale, then crop it into 8 pieces á 8064x8064px, at the end force alpha off:
   ############################
   if [ ! -s "tmp/night_7.mpc" ]
   then
     convert -monitor tmp/nightlights_32256x16128_lowColorsCut.mpc -colorspace Gray -crop 8064x8064 +repage -alpha Off tmp/night_%d.mpc
   else echo "=> Skipping existing files: tmp/night_[0-7].mpc"
   fi

   ############################
   ## convert night_[0-7].mpc to FG name convention [NS][1-4] and invert colors (light = transparent, dark = opaque)
   ############################
   for f in $IM
   do
     IM2FG $f
     if [ ! -s "tmp/night_${DEST}.mpc" ]
     then
       convert -monitor tmp/night_${f}.mpc -negate tmp/night_${DEST}.mpc
     else echo "=> Skipping existing file: tmp/night_${DEST}.mpc"
     fi
   done

   ##############################
   ##  Prepare world textures  ##
   ##############################

   ############################################
   ## Resize the NASA-Originals to 8k-(2*64) ##
   ############################################
   for t in $NASA
   do
     NasaToFG $t
     if [ ! -s "tmp/world_seamless_8064_${DEST}.mpc" ]
     then
       convert -monitor input/world.200408.3x21600x21600.${t}.png -resize 8064x8064 tmp/world_seamless_8064_${DEST}.mpc
     else echo "=> Skipping existing file: tmp/world_seamless_8064_${DEST}.mpc"
     fi
   done


   #################################################
   ## Copy nightlights into world's alpha channel ##
   #################################################
   for t in $TILES
   do
     if [ ! -s "tmp/world_seamless_8064_${t}_composite.mpc" ]
     then
       convert -monitor tmp/world_seamless_8064_${t}.mpc tmp/night_${t}_neg.mpc -compose CopyOpacity -composite tmp/world_seamless_8064_${t}_composite.mpc
     else echo "=> Skipping existing file: tmp/world_seamless_8064_${t}_composite.mpc"
     fi
   done


   ####################################
   ## Put a 64px border to each side ##
   ####################################
   for t in $TILES
   do
     if [ ! -s "tmp/world_seams_8k_${t}_emptyBorder.mpc" ]
     then
       convert -monitor tmp/world_seamless_8064_${t}_composite.mpc -bordercolor none -border 64 tmp/world_seams_8k_${t}_emptyBorder.mpc
     fi
     echo
     if [ ! -s "tmp/world_seams_8k_${t}.mpc" ]
     then
       cp tmp/world_seams_8k_${t}_emptyBorder.mpc tmp/world_seams_8k_${t}.mpc
       cp tmp/world_seams_8k_${t}_emptyBorder.cache tmp/world_seams_8k_${t}.cache
     else echo "=> Skipping existing file: tmp/world_seams_8k_${t}.mpc"
     fi
   done


   ########################################################
   ## crop borderline pixels and propagate till the edge ##
   ########################################################
   for t in $TILES
   do
     for b in $BORDERS
     do
       {
        if [ $b == "top" ]
        then
          CROP=$CROP_TOP
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_TOP
          CROPCORNER=$CROP_TOPRIGHT
          CORNER_POS="+8128+0"
          CORNER_NAME="topRight"
        fi
        if [ $b == "right" ]
        then
          CROP=$CROP_RIGHT
          RESIZE=$VERT_RESIZE
          POSITION=$POS_RIGHT
          CROPCORNER=$CROP_BOTTOMRIGHT
          CORNER_POS="+8128+8128"
          CORNER_NAME="bottomRight"
        fi
        if [ $b == "bottom" ]
        then
          CROP=$CROP_BOTTOM
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_BOTTOM
          CROPCORNER=$CROP_BOTTOMLEFT
          CORNER_POS="+0+8128"
          CORNER_NAME="bottomLeft"
        fi
        if [ $b == "left" ]
        then
          CROP=$CROP_LEFT
          RESIZE=$VERT_RESIZE
          POSITION=$POS_LEFT
          CROPCORNER=$CROP_TOPLEFT
          CORNER_POS="+0+0"
          CORNER_NAME="topLeft"
        fi
        echo
	convert -monitor tmp/world_seams_8k_${t}_emptyBorder.mpc -crop $CROP -resize $RESIZE\! tmp/world_${t}_seam_${b}.mpc
        convert -monitor tmp/world_seams_8k_${t}_emptyBorder.mpc -crop $CROPCORNER -resize 64x64\! tmp/world_${t}_seam_${CORNER_NAME}.mpc
        convert -monitor tmp/world_seams_8k_${t}.mpc world_${t}_seam_${b}.mpc -geometry $POSITION -composite tmp/world_seams_8k_${t}.mpc
        echo
        convert -monitor tmp/world_seams_8k_${t}.mpc world_${t}_seam_${CORNER_NAME}.mpc -geometry $CORNER_POS -composite tmp/world_seams_8k_${t}.mpc
        echo
       }
     done
     echo
     if [ ! -s "output/world_seams_8k_${t}.png" ]
     then
       convert -monitor tmp/world_seams_8k_${t}.mpc output/world_seams_8k_${t}.png
     else echo "=> Skipping existing file: output/world_seams_8k_${t}.png"
     fi
     if [ ! -s "output/world_seams_8k_${t}.dds" ]
     then
       convert -monitor tmp/world_seams_8k_${t}.mpc -flip -define dds:compression=dxt5 output/world_seams_8k_${t}.dds
     else echo "=> Skipping existing file: output/world_seams_8k_${t}.dds"
     fi
   done
   echo
   echo "World: [ done ]"
   echo
  }

function generateClouds
  {
   echo
   echo "#################################"
   echo "####    Processing clouds    ####"
   echo "#################################"
   echo

   mkdir -p tmp
   mkdir -p output

   ###########################################
   ## Prepare the raw images for processing ##
   ###########################################
   CT="E
W"
   if [ ! -s "tmp/cloud.T16k${t}.mpc" ]
   then
    {
     for t in $CT
     do
       convert -monitor input/cloud.${t}.2001210.21600x21600.png -resize 16128x16128 -alpha copy +level-colors white tmp/cloud.T16k${t}.mpc
     done
     echo
    }
   else echo "=> Skipping existing file: tmp/cloud.T16k${t}.mpc"
   fi

   #################################
   ## cut cloud images into tiles ##
   #################################
   if [ ! -s "tmp/clouds_7.mpc" ]
   then
    {
     convert -monitor tmp/cloud.T16kW.mpc -crop 8064x8064 +repage tmp/clouds_%d.mpc
     N="0
1
2
3"
     for t in $N
     do
       {
        if [ $t == "0" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_4.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_4.cache ; fi
        if [ $t == "1" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_5.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_5.cache ; fi
        if [ $t == "2" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_6.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_6.cache ; fi
        if [ $t == "3" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_7.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_7.cache ; fi
       }
     done
     convert -monitor tmp/cloud.T16kE.mpc -crop 8064x8064 +repage tmp/clouds_%d.mpc
     echo
    }
   else echo "=> Skipping existing files: tmp/clouds_[0-7].mpc"
   fi

   #######################################
   ## change names from [0-7] to [NS][1-4] and add 64px borders to the tiles
   #######################################
   for t in $IM
   do
     IM2FG $t
     if [ ! -s "tmp/clouds_${DEST}_emptyBorder.mpc" ]
     then
       convert -monitor tmp/clouds_${t}.mpc -bordercolor none -border 64 tmp/clouds_${DEST}_emptyBorder.mpc
       echo
     else echo "=> Skipping existing file: tmp/clouds_${DEST}_emptyBorder.mpc"
     fi
   done
   echo

   #######################################################
   ## add borders and propagate last pixels to the edge ##
   #######################################################
   for t in $TILES
   do
     for b in $BORDERS
     do
       {
        if [ $b == "top" ]
        then
          CROP=$CROP_TOP
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_TOP
          CROPCORNER=$CROP_TOPRIGHT
          CORNER_POS="+8128+0"
          CORNER_NAME="topRight"
        fi
        if [ $b == "right" ]
        then
          CROP=$CROP_RIGHT
          RESIZE=$VERT_RESIZE
          POSITION=$POS_RIGHT
          CROPCORNER=$CROP_BOTTOMRIGHT
          CORNER_POS="+8128+8128"
          CORNER_NAME="bottomRight"
        fi
        if [ $b == "bottom" ]
        then
          CROP=$CROP_BOTTOM
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_BOTTOM
          CROPCORNER=$CROP_BOTTOMLEFT
          CORNER_POS="+0+8128"
          CORNER_NAME="bottomLeft"
        fi
        if [ $b == "left" ]
        then
          CROP=$CROP_LEFT
          RESIZE=$VERT_RESIZE
          POSITION=$POS_LEFT
          CROPCORNER=$CROP_TOPLEFT
          CORNER_POS="+0+0"
          CORNER_NAME="topLeft"
        fi
        convert -monitor tmp/clouds_${t}_emptyBorder.mpc -crop $CROP -resize $RESIZE\! tmp/clouds_${t}_seam_${b}.mpc
        convert -monitor tmp/clouds_${t}_emptyBorder.mpc -crop $CROPCORNER -resize 64x64\! tmp/clouds_${t}_seam_${CORNER_NAME}.mpc
        convert -monitor tmp/clouds_${t}_emptyBorder.mpc tmp/clouds_${t}_seam_${b}.mpc -geometry $POSITION -composite tmp/clouds_${t}_emptyBorder.mpc
        echo
        convert -monitor tmp/clouds_${t}_emptyBorder.mpc tmp/clouds_${t}_seam_${CORNER_NAME}.mpc -geometry $CORNER_POS -composite tmp/clouds_${t}_emptyBorder.mpc
        echo
       }
     done
     echo
     cp tmp/clouds_${t}_emptyBorder.mpc tmp/clouds_seams_8k_${t}.mpc

     #########################################
     ## Convert to usable formats and sizes ##
     #########################################
     for r in $RESOLUTION
     do
       {
        mkdir -p tmp/$r
	if [ ! -s "tmp/${r}/clouds_seams_${t}.mpc" ]
        then
          convert -monitor tmp/clouds_seams_8k_${t}.mpc -resize ${r}x${r} tmp/${r}/clouds_seams_${t}.mpc
	else echo "=> Skipping existing file: tmp/clouds_${DEST}_emptyBorder.mpc"
        fi
	if [ ! -s "output/${r}/clouds_${t}.png" ]
        then
          convert -monitor tmp/${r}/clouds_seams_${t}.mpc -resize ${r}x${r} output/${r}/clouds_${t}.png
          echo
	else echo "=> Skipping existing file: output/${r}/clouds_${t}.png"
        fi
       }
     done
     echo
     echo "Clouds: [ done ]"
     echo
   done
  }

function cleanUp
  {
   for r in $RESOLUTION
   do
      rm -f tmp/${r}/*
      rmdir tmp/${r}
   done
   rm -f tmp/*
   rmdir tmp
  }



## Actual program:
if [ $DOWNLOAD == "true" ] ; then downloadImages ; fi
if [ $WORLD == "true" ] ;  then generateWorld ; fi
if [ $CLOUDS == "true" ] ; then generateClouds ; fi
if [ $CLEANUP == "true" ] ; then cleanUp ; fi




echo
echo "convert.sh has finished."
echo
echo "You will find the textures in \"output\" in your requested"
echo "resolution. Copy these to \$FGDATA/Models/Astro/*"
if [ $CLEANUP == "false" ]
then
  echo "If you're certain, that the generated textures are to your satisfaction"
  echo "you can delete folder tmp and thus free up disk space."
fi
