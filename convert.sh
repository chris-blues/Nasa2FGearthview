#!/bin/bash

VERSION="v0.04"

# make sure the script halts on error
set -e

function showHelp
  {
   echo "Nasa2FGearthview converter script $VERSION"
   echo "https://github.com/chris-blues/Nasa2FGearthview"
   echo
   echo "Usage:"
   echo "./convert.sh [ download world clouds 8k cleanup rebuild ]"
   echo
   echo "* Append \"nasa\" to download the needed images from NASA"
   echo "  -> This will download ca 2.4GB of data!"
   echo "  -> wget can continue interrupted downloads!"
   echo "  If omitted, it will download from my server, which is a lot"
   echo "  faster. See README for details."
   echo "* Append \"no-download\" to the command to skip the download"
   echo "  process alltogether. Only makes sense if you already got"
   echo "  the necessary data."
   echo "* Append \"world\" to the command to generate the world tiles"
   echo "* Append \"clouds\" to the command to generate cloud tiles"
   echo "* Append the size of the tiles (1k, 2k, 4, 8k). If you don't"
   echo "  pass a resolution, then all resolutions will be generated."
   echo "* Append \"cleanup\" to delete all temporary files in tmp/"
   echo "  Same as \"./convert.sh world clouds rebuild\""
   echo "  Useful if the source files have changed."
   echo "* Append \"rebuild\" to remove the corresponding temp-files"
   echo "  of your requested target."
   echo "  If you have \"world\" as target, that means all files in"
   echo "  tmp/world* and tmp/night* will be deleted, so that the"
   echo "  script will have to rebuild the entire set of files."
   echo "  So, if clouds and world are requested, effectively all temp-"
   echo "  files will be deleted (same as cleanup)"
   echo "  Useful if the source files have changed."
   echo "* Append \"check\" to let check the results. This will create"
   echo "  mosaics of the existing tiles. If no target is specified,"
   echo "  all 3 layers will be built: clouds world and nightlights."
   echo
   echo "If, for some reason, the script aborts, then it will try to"
   echo "skip the already completed steps, so you don't have to wait"
   echo "for the first steps to be redone. Those also happen to be the"
   echo "most heavy loads on the ressources."
   echo
   echo "WARNING!"
   echo "This script uses a _lot_ of disk space! Make sure you choose"
   echo "a disk, with at least 90GB free space."
   echo
   echo "This script will take a very long time, depending on your CPU"
   echo "and memory. It's propably best, to let it run over night..."
   echo
   echo "Examples:"
   echo "./convert.sh world clouds"
   echo "Will generate all textures needed for EarthView"
   echo
   echo "./convert.sh rebuild clouds no-download"
   echo "Will skip the download function and will proceed under the"
   echo "assumption that the download has previously finished"
   echo "correctly. Furthermore it will only generate the cloud-"
   echo "textures. Before that all temp-files will be deleted, so that"
   echo "the textures will be generated from scratch."
   echo
   echo "./convert.sh cleanup"
   echo "Will delete all temp-files, so that on the next run"
   echo "everything will have to be regenerated from scratch. Useful"
   echo "if the source images have changed."
   echo
   echo "./convert world 4k"
   echo "Will generate only tiles of the world of 4096x4096 size."
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
  if [ $ARG == "nasa" ] ; then DOWNLOAD="true" ; DL_LOCATION="NASA" ;  echo "Downloading from visibleearth.nasa.gov" ; fi
  if [ $ARG == "no-download" ] ; then DOWNLOAD="false" ; echo "Skipping the download process" ; fi
  if [ $ARG == "world" ] ; then WORLD="true" ; fi
  if [ $ARG == "clouds" ] ; then CLOUDS="true" ; fi
  if [ $ARG == "1k" ] ; then RESOLUTION="1024" ; fi
  if [ $ARG == "2k" ] ; then RESOLUTION="2048" ; fi
  if [ $ARG == "4k" ] ; then RESOLUTION="4096" ; fi
  if [ $ARG == "8k" ] ; then RESOLUTION="8192" ; fi
  if [ $ARG == "cleanup" ] ; then CLEANUP="true" ; fi
  if [ $ARG == "rebuild" ] ; then REBUILD="true" ; fi
  if [ $ARG == "check" ] ; then BUILDCHECKS="true" ; fi
done
if [ -z $DOWNLOAD ] ; then DOWNLOAD="true" ; fi
if [ -z $WORLD ] ; then WORLD="false" ; fi
if [ -z $CLOUDS ] ; then CLOUDS="false" ; fi
if [ -z $CLEANUP ] ; then CLEANUP="false" ; fi
if [ -z $REBUILD ] ; then REBUILD="false" ; fi
if [ -z $BUILDCHECKS ] ; then BUILDCHECKS="false" ; fi

if [ $WORLD == "false" ]
  then CHECK="world"
fi
if [ $CLOUDS == "false" ] 
  then
  if [ -z $CHECK ]
    then CHECK="clouds"
    else CHECK="all"
  fi
fi



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

ALTERNATE_URL="https://musicchris.de/download/FG/EarthView/raw-data-NASA.7z"
ALTERNATE_FILENAME="raw-data-NASA.7z"

if [ -z $RESOLUTION ]
  then 
    RESOLUTION="1024
2048
4096
8192
16384"
fi


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

CROP_TOP="16128x1+128+128"
CROP_RIGHT="1x16128+16254+128"
CROP_BOTTOM="16128x1+128+16254"
CROP_LEFT="1x16128+128+128"
CROP_TOPLEFT="1x1+128+128"
CROP_TOPRIGHT="1x1+16254+128"
CROP_BOTTOMRIGHT="1x1+16254+16254"
CROP_BOTTOMLEFT="1x1+128+16254"


## HORIZ meaning a horizontal bar, like the one on top
HORIZ_RESIZE="16128x128"
VERT_RESIZE="128x16128"

POS_TOP="+128+0"
POS_RIGHT="+16256+128"
POS_BOTTOM="+128+16254"
POS_LEFT="+0+128"


#################
##  FUNCTIONS  ##
#################

function rebuild
  {
   #############################################
   ##  Only remove tmp-files of given target  ##
   #############################################

   echo
   echo "########################################"
   echo "## Removing tmp-files of target world ##"
   echo "########################################"
   if [ $WORLD == "true" ]
   then
     {
      rm tmp/world*
      rm tmp/night*
     }
   fi

   echo
   echo "#########################################"
   echo "## Removing tmp-files of target clouds ##"
   echo "#########################################"
   if [ $CLOUDS == "true" ]
   then
     {
      rm tmp/cloud*
     }
   fi
  }

function cleanUp
  {
   echo
   echo "############################"
   echo "## Removing all tmp-files ##"
   echo "############################"
   rm -rv tmp/*
  }

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
   echo
   echo "###################################################"
   if [ ! -z $DL_LOCATION ]
     then echo "## Downloading images from visibleearth.nasa.gov ##"
     else echo "##    Downloading images from  musicchris.de     ##"
   fi
   echo "###################################################"
   if [ -z $DL_LOCATION ] ; then f=$ALTERNATE_URL ; fi
   FILENAME=$(echo $f | sed 's@.*/@@')
   if [ $WORLD == "true" ] 
   then
     if [ $DL_LOCATION == "NASA" ]
     then
       downloadWorld
     fi
   fi

   if [ $CLOUDS == "true" ]
   then
     if [ $DL_LOCATION == "NASA" ]
     then
       downloadClouds 
     fi
   fi

   if [ -z $DL_LOCATION ] ; then downloadMusicchris ; fi
  }

function downloadWorld
  {
   mkdir -p input
   echo "Downloading world tiles..."
   for f in $URLS_WORLD
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     wget --output-document=input/$FILENAME --continue --show-progress $f
   done
  }

function downloadClouds
  {
   mkdir -p input
   echo "Downloading cloud tiles..."
   for f in $URLS_CLOUDS
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     wget --output-document=input/$FILENAME --continue --show-progress $f
   done
  }

function downloadMusicchris
  {
   mkdir -p input
   echo "Downloading raw images... (ca 2.2 GB)"
   wget --output-document=input/$FILENAME --continue --show-progress $ALTERNATE_URL
   echo "Unpacking raw images..."
   cd input
   7z e -bt -y raw-data-NASA.7z
   cd ..
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

   echo
   echo "############################"
   echo "##  Prepare night lights  ##"
   echo "############################"
   echo
   echo "########################################"
   echo "## Convert to a more efficient format ##"
   echo "########################################"
   if [ ! -s "tmp/nightlights_54000x27000.mpc" ]
   then
     env MAGICK_TMPDIR=${PWD}/tmp nice -10 convert -monitor -limit memory 32 -limit map 32 input/dnb_land_ocean_ice.2012.54000x27000_geo.tif tmp/nightlights_54000x27000.mpc
   else echo "=> Skipping existing file: tmp/nightlights_54000x27000.mpc"
   fi

   echo
   echo "########################"
   echo "## Resize nightlights ##"
   echo "########################"
   if [ ! -s "tmp/nightlights_32256x16128.mpc" ]
   then
     env MAGICK_TMPDIR=${PWD}/tmp nice -10 convert -monitor -limit memory 32 -limit map 32 tmp/nightlights_54000x27000.mpc -resize 32256x16128 tmp/nightlights_32256x16128.mpc
   else echo "=> Skipping existing file: tmp/nightlights_32256x16128.mpc"
   fi

   echo
   echo "#############################################"
   echo "## Filter out low colors (continents, ice) ##"
   echo "#############################################"
   if [ ! -s "tmp/nightlights_32256x16128_lowColorsCut.mpc" ]
   then
     env MAGICK_TMPDIR=${PWD}/tmp nice -10 convert -monitor -limit memory 32 -limit map 32 tmp/nightlights_32256x16128.mpc -channel R -level 7.8%,100%,1.5 -channel G -level 13.7%,100%,1.5 -channel B -level 33%,100%,1.5 +channel tmp/nightlights_32256x16128_lowColorsCut.mpc
   else echo "=> Skipping existing file: tmp/nightlights_32256x16128_lowColorsCut.mpc"
   fi

   echo
   echo "######################################"
   echo "## cut nightlight images into tiles ##"
   echo "######################################"
   if [ ! -s "tmp/night_7.mpc" ]
   then
     convert -monitor tmp/nightlights_32256x16128_lowColorsCut.mpc -colorspace Gray -crop 8064x8064 +repage -alpha Off tmp/night_%d.mpc
   else echo "=> Skipping existing files: tmp/night_[0-7].mpc"
   fi

   echo
   echo "###################"
   echo "## invert colors ##"
   echo "###################"
   for f in $IM
   do
     IM2FG $f
     if [ ! -s "tmp/night_${DEST}_neg.mpc" ]
     then
       convert -monitor tmp/night_${f}.mpc -negate tmp/night_${DEST}_neg.mpc
     else echo "=> Skipping existing file: tmp/night_${DEST}_neg.mpc"
     fi
   done

   echo
   echo "##############################"
   echo "##  Prepare world textures  ##"
   echo "##############################"
   echo
   echo "############################################"
   echo "## Resize the NASA-Originals to 8k-(2*64) ##"
   echo "############################################"
   for t in $NASA
   do
     NasaToFG $t
     if [ ! -s "tmp/world_seamless_8064_${DEST}.mpc" ]
     then
       {
        ## Workaround for tiles N3 and N4 - there's a gray failure area at the top border - let's remove it!
        if [ $t == "C1" ]
        then
          # pick a sample pixel. The polar regions are all equally colored.
          convert -monitor tmp/world_seamless_8064_N2.mpc -crop 1x1+1+1 -resize 8192x582\! tmp/bluebar.mpc
        fi
        if [ $t == "C1" -o $t == "D1" ]
        then
          {
           # copy the sample over to the tile:
           convert -monitor input/world.200408.3x21600x21600.${t}.png -resize 8064x8064 tmp/bluebar.mpc -geometry +0+0 -composite tmp/world_seamless_8064_${DEST}.mpc
           echo
          }
        else
          {
           convert -monitor input/world.200408.3x21600x21600.${t}.png -resize 8064x8064 tmp/world_seamless_8064_${DEST}.mpc
	  }
	fi
       }
     else echo "=> Skipping existing file: tmp/world_seamless_8064_${DEST}.mpc"
     fi
   done

   echo
   echo "##################################################"
   echo "## Merge nightlights into world's alpha channel ##"
   echo "##################################################"
   for t in $TILES
   do
     if [ ! -s "tmp/world_seamless_8064_${t}_composite.mpc" ]
     then
       convert -monitor tmp/world_seamless_8064_${t}.mpc tmp/night_${t}_neg.mpc -compose CopyOpacity -composite tmp/world_seamless_8064_${t}_composite.mpc
     else echo "=> Skipping existing file: tmp/world_seamless_8064_${t}_composite.mpc"
     fi
   done

   echo
   echo "####################################"
   echo "## Put a 64px border to each side ##"
   echo "####################################"
   for t in $TILES
   do
     if [ ! -s "tmp/world_seams_8k_${t}_emptyBorder.mpc" ]
     then
       convert -monitor tmp/world_seamless_8064_${t}_composite.mpc -bordercolor none -border 64 tmp/world_seams_8k_${t}_emptyBorder.mpc
       echo
     fi
     if [ ! -s "tmp/world_seams_8k_${t}.mpc" ]
     then
       cp tmp/world_seams_8k_${t}_emptyBorder.mpc tmp/world_seams_8k_${t}.mpc
       cp tmp/world_seams_8k_${t}_emptyBorder.cache tmp/world_seams_8k_${t}.cache
     else echo "=> Skipping existing file: tmp/world_seams_8k_${t}.mpc"
     fi
   done

   echo
   echo "######################################################"
   echo "## crop borderline pixels and propagate to the edge ##"
   echo "######################################################"
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
        convert -monitor tmp/world_seams_8k_${t}.mpc tmp/world_${t}_seam_${b}.mpc -geometry $POSITION -composite tmp/world_seams_8k_${t}.mpc
        echo
        convert -monitor tmp/world_seams_8k_${t}.mpc tmp/world_${t}_seam_${CORNER_NAME}.mpc -geometry $CORNER_POS -composite tmp/world_seams_8k_${t}.mpc
        echo
       }
     done
     echo

     echo
     echo "#############################"
     echo "## Final output of tile $t ##"
     echo "#############################"
     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        echo
        echo "--> Writing output/${r}/pale_blue_aug_${t}.dds @ ${r}x${r}"
	convert -monitor tmp/world_seams_8k_${t}.mpc -resize ${r}x${r} -flip -define dds:compression=dxt5 output/${r}/pale_blue_aug_${t}.dds
	echo
	echo "--> Writing output/${r}/pale_blue_aug_${t}.png @ ${r}x${r}"
	convert -monitor tmp/world_seams_8k_${t}.mpc -resize ${r}x${r} output/${r}/pale_blue_aug_${t}.png
	echo
       }
     done
     echo
     echo "World $t [ done ]"
     echo



   done
   echo "###############################"
   echo "####    World: [ done ]    ####"
   echo "###############################"

   if [ $BUILDCHECKS == "true" ]
     then
     CHECK="world"
     checkResults
   fi
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

   echo "######################################"
   echo "## Resize images to 16k resolution, ##"
   echo "## copy image to alpha-channel and  ##"
   echo "## paint the canvas white (#FFFFFF) ##"
   echo "######################################"
   CT="E
W"
   for t in $CT
   do
     if [ ! -s "tmp/cloud.T16k${t}.mpc" ]
     then
       convert -monitor input/cloud.${t}.2001210.21600x21600.png -resize 16128x16128 -alpha copy +level-colors white tmp/cloud.T16k${t}.mpc
     else echo "=> Skipping existing file: tmp/cloud.T16k${t}.mpc"
     fi
   done
   echo


   echo
   echo "####################################"
   echo "## cut cloud images into 8k tiles ##"
   echo "####################################"
   if [ ! -s "tmp/clouds_S2.mpc" ]
   then
    {
     convert -monitor tmp/cloud.T16kE.mpc -crop 8064x8064 +repage tmp/clouds_%d.mpc
     N="0
1
2
3"
     for t in $N
     do
       {
        if [ $t == "0" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_N3.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_N3.cache ; fi
        if [ $t == "1" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_N4.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_N4.cache ; fi
        if [ $t == "2" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_S3.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_S3.cache ; fi
        if [ $t == "3" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_S4.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_S4.cache ; fi
       }
     done
    }
   else echo "=> Skipping existing files: tmp/clouds_[N3-S4].mpc"
   fi
   if [ ! -s "tmp/clouds_S2.mpc" ]
   then
    {
     convert -monitor tmp/cloud.T16kW.mpc -crop 8064x8064 +repage tmp/clouds_%d.mpc
     echo
     for t in $N
     do
       {
        if [ $t == "0" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_N1.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_N1.cache ; fi
        if [ $t == "1" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_N2.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_N2.cache ; fi
        if [ $t == "2" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_S1.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_S1.cache ; fi
        if [ $t == "3" ] ; then mv tmp/clouds_${t}.mpc tmp/clouds_S2.mpc ; mv tmp/clouds_${t}.cache tmp/clouds_S2.cache ; fi
       }
     done
    }
   else echo "=> Skipping existing files: tmp/clouds_[N1-S2].mpc"
   fi

   echo
   echo "###################################"
   echo "## add 64px borders to the tiles ##"
   echo "###################################"
   for t in $TILES
   do
     if [ ! -s "tmp/clouds_${t}_emptyBorder.mpc" ]
     then
       convert -monitor tmp/clouds_${t}.mpc -bordercolor none -border 64 tmp/clouds_${t}_emptyBorder.mpc
       echo
     else echo "=> Skipping existing file: tmp/clouds_${t}_emptyBorder.mpc"
     fi
   done
   echo

   echo
   echo "#######################################"
   echo "## propagate last pixels to the edge ##"
   echo "#######################################"
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

     echo
     echo "#############################"
     echo "## Final output of tile $t ##"
     echo "#############################"
     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        echo
        echo "--> Writing output/${r}/clouds_${t}.png @ ${r}x${r}"
	convert -monitor tmp/clouds_${t}_emptyBorder.mpc -resize ${r}x${r} output/${r}/clouds_${t}.png
       }
     done
     echo
     echo "Cloud $t [ done ]"
     echo
   done
   echo "################################"
   echo "####    Clouds: [ done ]    ####"
   echo "################################"

   if [ $BUILDCHECKS == "true" ]
     then
     CHECK="clouds"
     checkResults
   fi
  }

function checkResults
  {
   echo
   echo "##############################################"
   echo "##  Creating a mosaic of the created tiles  ##"
   echo "##############################################"
   echo

   RES=8192
   for r in $RESOLUTION
   do
     if [ $r -le $RES ]
     then
       RES=$r
     fi
   done
   let "WIDTH = 4 * $RES"
   let "HEIGHT = 2 * $RES"
   echo "Lowest available resolution is: $RES"

   if [ $CHECK == "clouds" -o $CHECK == "all" ]
   then
     {
      echo "checking clouds..."
      echo

      echo "Creating canvas ${WIDTH}x${HEIGHT}"
      convert -size ${WIDTH}x${HEIGHT} xc:Black -alpha on check_clouds.png

      POS=0
      for t in 1 2 3 4
      do
        convert -monitor check_clouds.png output/${RES}/clouds_N${t}.png -geometry +${POS}+0 -composite check_clouds.png
        echo
        convert -monitor check_clouds.png output/${RES}/clouds_S${t}.png -geometry +${POS}+${RES} -composite check_clouds.png
        echo
        let "POS += $RES"
      done
      mogrify -monitor -resize 4096x2048 check_clouds.png
     }
   fi

   if [ $CHECK == "world" -o $CHECK == "all" ]
   then
     {
      echo "checking world..."
      echo

      echo "Creating canvas ${WIDTH}x${HEIGHT}"
      convert -size ${WIDTH}x${HEIGHT} xc:Black -alpha on check_world.png

      POS=0
      for t in 1 2 3 4
      do
        convert -monitor check_world.png output/${RES}/pale_blue_aug_N${t}.png -alpha Off -geometry +${POS}+0 -composite check_world.png
        echo
        convert -monitor check_world.png output/${RES}/pale_blue_aug_S${t}.png -alpha Off -geometry +${POS}+${RES} -composite check_world.png
        echo
        let "POS += $RES"
      done
      mogrify -monitor -resize 4096x2048 check_world.png

      for f in $TILES
      do
        convert -monitor tmp/night_${f}_neg.mpc -resize 1024x1024 -negate tmp/night_${f}_check.mpc
      done
      montage -monitor -mode concatenate -tile 4x tmp/night_??_check.mpc check_night.png
     }
   fi
  }



###############################
####    Actual program:    ####
###############################

echo
echo "--------------------------------------------------------------"
echo
echo "Processing starts..."
echo
printf "Target:     "
if [ $CLOUDS == "true" ] ; then printf "clouds " ; fi
if [ $WORLD == "true" ] ;  then printf "world" ; fi
echo
printf "Resolution: "
for r in $RESOLUTION ; do printf "%sx%s " $r $r ; done
echo
echo
echo "--------------------------------------------------------------"
echo

for r in $RESOLUTION
do
  mkdir -p output/$r
done

if [ $REBUILD == "true" ] ; then rebuild ; fi
if [ $DOWNLOAD == "true" ] ; then downloadImages ; fi
if [ $WORLD == "true" ] ;  then generateWorld ; fi
if [ $CLOUDS == "true" ] ; then generateClouds ; fi
if [ $BUILDCHECKS == "true" ] ; then checkResults ; fi
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
  echo "./convert.sh cleanup"
  echo "or"
  echo "rm -r tmp/"
fi
