#!/bin/bash

VERSION="v0.10"

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
   echo "* Append the size of the tiles (1k, 2k, 4, 8k, 16k). If you"
   echo "  don't pass a resolution, then all resolutions will be"
   echo "  generated."
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
  if [ $ARG == "all" ] ; then WORLD="true" ; CLOUDS="true" ; fi
  if [ $ARG == "1k" ] ; then RESOLUTION="1024" ; fi
  if [ $ARG == "2k" ] ; then RESOLUTION="2048" ; fi
  if [ $ARG == "4k" ] ; then RESOLUTION="4096" ; fi
  if [ $ARG == "8k" ] ; then RESOLUTION="8192" ; fi
  if [ $ARG == "16k" ] ; then RESOLUTION="16384" ; fi
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
export MAGICK_TMPDIR=${PWD}/tmp

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
    NO_RESOLUTION_GIVEN="true"
    RESOLUTION_MAX="16384"
fi
if [ -z $RESOLUTION_MAX ] ; then RESOLUTION_MAX=$RESOLUTION ; fi
let "BORDER_WIDTH = $RESOLUTION_MAX / 128"
let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - 1"

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


#################
##  FUNCTIONS  ##
#################

function rebuild
  {
   #############################################
   ##  Only remove tmp-files of given target  ##
   #############################################

   if [ $WORLD == "true" ]
   then
     {
      echo
      echo "########################################"
      echo "## Removing tmp-files of target world ##"
      echo "########################################"
      rm tmp/world*
      rm tmp/night*
     }
   fi

   if [ $CLOUDS == "true" ]
   then
     {
      echo
      echo "#########################################"
      echo "## Removing tmp-files of target clouds ##"
      echo "#########################################"
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

function prettyTime
  {
   if [ $SECS -gt 60 ]
     then let "MINUTES = $SECS / 60"
     else MINUTES=0
   fi
   if [ $MINUTES -gt 60 ]
     then let "HOURS = $MINUTES / 60"
     else HOURS=0
   fi
   if [ $HOURS -gt 24 ]
     then let "DAYS = $HOURS / 24"
     else DAYS=0
   fi
   if [ $DAYS -gt 0 ] ; then let "HOURS = $HOURS - ( $DAYS * 24 )" ; fi
   if [ $HOURS -gt 0 ] ; then let "MINUTES = $MINUTES - ( ( ( $DAYS * 24 ) + $HOURS ) * 60 )" ; fi
   if [ $MINUTES -gt 0 ] ; then let "SECS = $SECS - ( ( ( ( ( $DAYS * 24 ) + $HOURS ) * 60 ) + $MINUTES ) * 60 )" ; fi
  }

function getProcessingTime
  {
   ENDTIME=$(date +%s)
   if [ $LASTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $LASTTIME"
   fi
   prettyTime
   OUTPUTSTRING="${SECS}s"
   if [ $MINUTES -gt 0 ] ; then OUTPUTSTRING="${MINUTES}m ${SECS}s" ; fi
   if [ $HOURS -gt 0 ] ; then OUTPUTSTRING="${HOURS}h ${MINUTES}m ${SECS}s" ; fi
   if [ $DAYS -gt 0 ] ; then OUTPUTSTRING="${DAYS}d ${HOURS}h ${MINUTES}m ${SECS}s" ; fi
   echo "Processing time: $OUTPUTSTRING" | tee -a log.txt
   LASTTIME=$ENDTIME
  }

function NASA2FG
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
   echo | tee -a log.txt
   echo "###################################################" | tee -a log.txt
   if [ ! -z $DL_LOCATION ]
     then echo "## Downloading images from visibleearth.nasa.gov ##" | tee -a log.txt
     else echo "##    Downloading images from  musicchris.de     ##" | tee -a log.txt
   fi
   echo "###################################################" | tee -a log.txt
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
   echo "Downloading world tiles..." | tee -a log.txt
   for f in $URLS_WORLD
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     wget --output-document=input/$FILENAME --continue --show-progress $f 2>> log.txt
   done
  }

function downloadClouds
  {
   mkdir -p input
   echo "Downloading cloud tiles..." | tee -a log.txt
   for f in $URLS_CLOUDS
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     wget --output-document=input/$FILENAME --continue --show-progress $f 2>> log.txt
   done
  }

function downloadMusicchris
  {
   mkdir -p input
   echo "Downloading raw images... (ca 2.2 GB)" | tee -a log.txt
   wget --output-document=input/$FILENAME --continue --show-progress $ALTERNATE_URL 2>> log.txt
   echo "Unpacking raw images..." | tee -a log.txt
   cd input
   7z e -bt -y raw-data-NASA.7z 2>> log.txt
   cd ..
  }

function generateWorld
  {
   STARTTIME=$(date +%s)
   echo | tee -a log.txt
   echo "################################" | tee -a log.txt
   echo "####    Processing World    ####" | tee -a log.txt
   echo "################################" | tee -a log.txt
   echo | tee -a log.txt

   mkdir -p tmp
   mkdir -p output

   echo | tee -a log.txt
   echo "############################" | tee -a log.txt
   echo "##  Prepare night lights  ##" | tee -a log.txt
   echo "############################" | tee -a log.txt
   echo | tee -a log.txt
   echo "########################################" | tee -a log.txt
   echo "## Convert to a more efficient format ##" | tee -a log.txt
   echo "########################################" | tee -a log.txt
   if [ ! -s "tmp/nightlights_54000x27000.mpc" ]
   then
     set -x
       convert \
         -monitor \
         -limit memory 32 \
         -limit map 32 \
         input/dnb_land_ocean_ice.2012.54000x27000_geo.tif \
         tmp/nightlights_54000x27000.mpc
     set +x
   else echo "=> Skipping existing file: tmp/nightlights_54000x27000.mpc" | tee -a log.txt
   fi
   LASTTIME=$STARTTIME
   # 1m, 59s
   getProcessingTime

   echo | tee -a log.txt
   echo "########################" | tee -a log.txt
   echo "## Resize nightlights ##" | tee -a log.txt
   echo "########################" | tee -a log.txt
   let "RESIZE_W = ( $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH ) ) * 4"
   let "RESIZE_H = ( $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH ) ) * 2"
   if [ ! -s "tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc" ]
   then
     set -x
       convert \
         -monitor \
         -limit memory 32 \
         -limit map 32 \
         tmp/nightlights_54000x27000.mpc \
         -resize ${RESIZE_W}x${RESIZE_H} \
         tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc
     set +x
   else echo "=> Skipping existing file: tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc" | tee -a log.txt
   fi
   # 3h, 47m, 29s
   getProcessingTime

   echo | tee -a log.txt
   echo "#############################################" | tee -a log.txt
   echo "## Filter out low colors (continents, ice) ##" | tee -a log.txt
   echo "#############################################" | tee -a log.txt
   if [ ! -s "tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc" ]
   then
     set -x
       convert \
         -monitor \
         -limit memory 32 \
         -limit map 32 \
         tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc \
         -channel R -level 7.8%,100%,1.5 \
         -channel G -level 13.7%,100%,1.5 \
         -channel B -level 33%,100%,1.5 \
         +channel \
         tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc
     set +x
   else echo "=> Skipping existing file: tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc" | tee -a log.txt
   fi
   # 1h, 8m, 52s
   getProcessingTime

   echo | tee -a log.txt
   echo "#####################################" | tee -a log.txt
   echo "## cut nightlight image into tiles ##" | tee -a log.txt
   echo "#####################################" | tee -a log.txt
   if [ ! -s "tmp/night_7.mpc" ]
   then
     set -x
     convert \
       -monitor \
       -limit memory 32 \
       -limit map 32 \
       tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc \
       -crop ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} +repage \
       -alpha Off \
       tmp/night_${IMAGE_BORDERLESS}_%d.mpc
     set +x
   else echo "=> Skipping existing files: tmp/night_[0-7].mpc" | tee -a log.txt
   fi
   # 41m, 43s
   getProcessingTime

   echo | tee -a log.txt
   echo "###################" | tee -a log.txt
   echo "## invert colors ##" | tee -a log.txt
   echo "###################" | tee -a log.txt
   for f in $IM
   do
     IM2FG $f
     if [ ! -s "tmp/night_${IMAGE_BORDERLESS}_${DEST}_neg.mpc" ]
     then
       set -x
       convert \
         -monitor \
         tmp/night_${IMAGE_BORDERLESS}_${f}.mpc \
         -negate \
         tmp/night_${IMAGE_BORDERLESS}_${DEST}_neg.mpc
       set +x
     else echo "=> Skipping existing file: tmp/night_${DEST}_neg.mpc" | tee -a log.txt
     fi
   done
   # 5m, 33s
   getProcessingTime

   echo | tee -a log.txt
   echo "##############################" | tee -a log.txt
   echo "##  Prepare world textures  ##" | tee -a log.txt
   echo "##############################" | tee -a log.txt
   echo | tee -a log.txt
   echo "################################################" | tee -a log.txt
   echo "## Resize the NASA-Originals to ${RESOLUTION}-(2*${BORDER_WIDTH}) ##" | tee -a log.txt
   echo "################################################" | tee -a log.txt
   for t in $NASA
   do
     NASA2FG $t
     if [ ! -s "tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" ]
     then
       {
        ## Workaround for tiles N3 and N4 - there's a gray failure area at the top border - let's remove it!
        if [ $t == "C1" ]
        then
          # pick a sample pixel. The polar regions are all equally colored.
          let "OVERLAY_HEIGHT = ${RESOLUTION} / 14"
          set -x
          convert \
            -monitor \
            -limit memory 32 \
            -limit map 32 \
            tmp/world_seamless_${IMAGE_BORDERLESS}_N2.mpc \
            -crop 1x1+1+1 \
            -resize ${IMAGE_BORDERLESS}x${OVERLAY_HEIGHT}\! \
            tmp/bluebar.mpc
	  set +x
        fi
        if [ $t == "C1" -o $t == "D1" ]
        then
          {
           # copy the sample over to the tile:
           set -x
           convert \
             -monitor \
             -limit memory 32 \
             -limit map 32 \
             input/world.200408.3x21600x21600.${t}.png \
             -resize ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
             tmp/bluebar.mpc \
             -geometry +0+0 \
             -composite \
             tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	   set +x
           echo
          }
        else
          {
           set -x
           convert \
             -monitor \
             -limit memory 32 \
             -limit map 32 \
             input/world.200408.3x21600x21600.${t}.png \
             -resize ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
             tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
	   set +x
	  }
	fi
       }
     else echo "=> Skipping existing file: tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a log.txt
     fi
   done
   # 3h, 12m, 9s
   getProcessingTime

   echo | tee -a log.txt
   echo "##################################################" | tee -a log.txt
   echo "## Merge nightlights into world's alpha channel ##" | tee -a log.txt
   echo "##################################################" | tee -a log.txt
   for t in $TILES
   do
     if [ ! -s "tmp/world_seamless_${IMAGE_BORDERLESS}_${t}_composite.mpc" ]
     then
       set -x
       convert \
         -monitor \
         tmp/world_seamless_${IMAGE_BORDERLESS}_${t}.mpc \
         tmp/night_${IMAGE_BORDERLESS}_${t}_neg.mpc \
         -compose CopyOpacity \
         -composite \
         tmp/world_seamless_${IMAGE_BORDERLESS}_${t}_composite.mpc
       set +x
     else echo "=> Skipping existing file: tmp/world_seamless_${IMAGE_BORDERLESS}_${t}_composite.mpc" | tee -a log.txt
     fi
   done
   # 11m, 26s
   getProcessingTime

   echo | tee -a log.txt
   echo "#####################################" | tee -a log.txt
   echo "## Put a ${BORDER_WIDTH}px border to each side ##" | tee -a log.txt
   echo "#####################################" | tee -a log.txt
   for t in $TILES
   do
     if [ ! -s "tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" ]
     then
       set -x
       convert \
         -monitor \
         tmp/world_seamless_${IMAGE_BORDERLESS}_${t}_composite.mpc \
         -bordercolor none \
         -border ${BORDER_WIDTH} \
         tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc
       set +x
       echo
     fi
     if [ ! -s "tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc" ]
     then
       set -x
       cp tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc
       cp tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.cache tmp/world_seams_${RESOLUTION_MAX}_${t}.cache
       set +x
     else echo "=> Skipping existing file: tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc" | tee -a log.txt
     fi
   done
   # 11m, 24s
   getProcessingTime

   echo | tee -a log.txt
   echo "######################################################" | tee -a log.txt
   echo "## crop borderline pixels and propagate to the edge ##" | tee -a log.txt
   echo "######################################################" | tee -a log.txt

   CROP_TOP="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_RIGHT="1x${IMAGE_BORDERLESS}+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOM="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
   CROP_LEFT="1x${IMAGE_BORDERLESS}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPLEFT="1x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPRIGHT="1x1+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOMRIGHT="1x1+${IMAGE_WITH_BORDER}+${IMAGE_WITH_BORDER}"
   CROP_BOTTOMLEFT="1x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"

   ## HORIZ meaning a horizontal bar, like the one on top
   HORIZ_RESIZE="${IMAGE_BORDERLESS}x${BORDER_WIDTH}"
   VERT_RESIZE="${BORDER_WIDTH}x${IMAGE_BORDERLESS}"

   POS_TOP="+${BORDER_WIDTH}+0"
   POS_RIGHT="+${IMAGE_WITH_BORDER_POS}+${BORDER_WIDTH}"
   POS_BOTTOM="+${BORDER_WIDTH}+${IMAGE_WITH_BORDER_POS}"
   POS_LEFT="+0+${BORDER_WIDTH}"

   for t in $TILES
   do
     if [ ! -s "tmp/world_${RESOLUTION_MAX}_done_${t}.mpc" ]
     then
     for b in $BORDERS
     do
       {
        if [ $b == "top" ]
        then
          CROP=$CROP_TOP
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_TOP
          CROPCORNER=$CROP_TOPRIGHT
          CORNER_POS="+${IMAGE_WITH_BORDER_POS}+0"
          CORNER_NAME="topRight"
        fi
        if [ $b == "right" ]
        then
          CROP=$CROP_RIGHT
          RESIZE=$VERT_RESIZE
          POSITION=$POS_RIGHT
          CROPCORNER=$CROP_BOTTOMRIGHT
          CORNER_POS="+${IMAGE_WITH_BORDER_POS}+${IMAGE_WITH_BORDER_POS}"
          CORNER_NAME="bottomRight"
        fi
        if [ $b == "bottom" ]
        then
          CROP=$CROP_BOTTOM
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_BOTTOM
          CROPCORNER=$CROP_BOTTOMLEFT
          CORNER_POS="+0+${IMAGE_WITH_BORDER_POS}"
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
        set -x
	convert \
	  -monitor \
	  tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
	  -crop $CROP \
	  -resize $RESIZE\! \
	  tmp/world_${RESOLUTION_MAX}_${t}_seam_${b}.mpc
        convert \
          -monitor \
          tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
          -crop $CROPCORNER \
          -resize ${BORDER_WIDTH}x${BORDER_WIDTH}\! \
          tmp/world_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc
        convert \
          -monitor \
          tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc \
          tmp/world_${RESOLUTION_MAX}_${t}_seam_${b}.mpc \
          -geometry $POSITION \
          -composite \
          tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc
        echo
        convert \
          -monitor \
          tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc \
          tmp/world_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc \
          -geometry $CORNER_POS \
          -composite \
          tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc
	set +x
        echo
       }
     done
     echo
     set -x
     cp -v tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc tmp/world_${RESOLUTION_MAX}_done_${t}.mpc | tee -a log.txt
     cp -v tmp/world_seams_${RESOLUTION_MAX}_${t}.cache tmp/world_${RESOLUTION_MAX}_done_${t}.cache | tee -a log.txt
     set +x

     else echo "=> Skipping existing file: tmp/world_${RESOLUTION_MAX}_done_${t}.mpc" | tee -a log.txt
     fi

  done
  # 37m, 6s
  getProcessingTime

  for t in $TILES
   do
     echo | tee -a log.txt
     echo "#############################" | tee -a log.txt
     echo "## Final output of tile $t ##" | tee -a log.txt
     echo "#############################" | tee -a log.txt
     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        echo
        echo "--> Writing output/${r}/world_${t}.dds @ ${r}x${r}"
        set -x
	convert \
	  -monitor \
	  tmp/world_${RESOLUTION_MAX}_done_${t}.mpc \
	  -resize ${r}x${r} \
	  -flip \
	  -define dds:compression=dxt5 \
	  output/${r}/world_${t}.dds
	set +x
	echo
	echo "--> Writing output/${r}/world_${t}.png @ ${r}x${r}"
	set -x
	convert \
	  -monitor \
	  tmp/world_${RESOLUTION_MAX}_done_${t}.mpc \
	  -resize ${r}x${r} \
	  output/${r}/world_${t}.png
	set +x
	echo
       }
     done

     echo | tee -a log.txt
     echo "World $t [ done ]" | tee -a log.txt
     echo | tee -a log.txt

   done
   echo "###############################" | tee -a log.txt
   echo "####    World: [ done ]    ####" | tee -a log.txt
   echo "###############################" | tee -a log.txt
   # 2h, 19m, 7s
   # Overall processing time: 44089 s
   # Overall processing time: 0 d, 2 h, 19 m, 7 s

   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $SECS s" | tee -a log.txt
   prettyTime
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s" | tee -a log.txt

   if [ $BUILDCHECKS == "true" ]
     then
     CHECK="world"
     checkResults
   fi
  }

function generateClouds
  {
   if [ -z $STARTTIME ] ; then STARTTIME=$(date +%s) ; fi
   # maximum cloud-tile resolution is 8192, since we have no big enough source files...
   if [ $RESOLUTION_MAX -eq 16384 ] ; then RESOLUTION_MAX=8192 ; fi
   let "BORDER_WIDTH = $RESOLUTION_MAX / 128"
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - 1"
   let "SIZE = 2 * $IMAGE_BORDERLESS"

   echo | tee -a log.txt
   echo "#################################" | tee -a log.txt
   echo "####    Processing clouds    ####" | tee -a log.txt
   echo "#################################" | tee -a log.txt
   echo | tee -a log.txt

   mkdir -p tmp
   mkdir -p output

   echo "######################################" | tee -a log.txt
   echo "## Resize images to ${SIZE} resolution, ##" | tee -a log.txt
   echo "## copy image to alpha-channel and  ##" | tee -a log.txt
   echo "## paint the canvas white (#FFFFFF) ##" | tee -a log.txt
   echo "######################################" | tee -a log.txt
   CT="E
W"
   for t in $CT
   do
     if [ ! -s "tmp/cloud_T_${SIZE}_${t}.mpc" ]
     then
       convert \
         -monitor \
         input/cloud.${t}.2001210.21600x21600.png \
         -resize ${SIZE}x${SIZE} \
         -alpha copy \
         +level-colors white \
         tmp/cloud_T_${SIZE}_${t}.mpc
     else echo "=> Skipping existing file: tmp/cloud_T_${SIZE}_${t}.mpc" | tee -a log.txt
     fi
   done
   echo
   # 6m, 4s
   if [ -z $LASTTIME ] ; then LASTTIME=$STARTTIME ; fi
   getProcessingTime

   echo | tee -a log.txt
   echo "#################################" | tee -a log.txt
   echo "## cut cloud images into tiles ##" | tee -a log.txt
   echo "#################################" | tee -a log.txt
   if [ ! -s "tmp/clouds_S2.mpc" ]
   then
    {
     convert \
       -monitor \
       tmp/cloud_T_${SIZE}_E.mpc \
       -crop ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
       +repage \
       tmp/clouds_${IMAGE_BORDERLESS}_%d.mpc
     N="0
1
2
3"
     for t in $N
     do
       {
        if [ $t == "0" ]
	then
	  mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_N3.mpc
	  mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_N3.cache
	fi
        if [ $t == "1" ]
        then
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_N4.mpc
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_N4.cache
	fi
        if [ $t == "2" ]
        then
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_S3.mpc
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_S3.cache
	fi
        if [ $t == "3" ]
	then
	  mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_S4.mpc
	  mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_S4.cache
	fi
       }
     done
    }
   else echo "=> Skipping existing files: tmp/clouds_${IMAGE_BORDERLESS}_[N3-S4].mpc" | tee -a log.txt
   fi
   if [ ! -s "tmp/clouds_${IMAGE_BORDERLESS}_S2.mpc" ]
   then
    {
     convert \
       -monitor \
       tmp/cloud_T_${SIZE}_W.mpc \
       -crop ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
       +repage \
       tmp/clouds_${IMAGE_BORDERLESS}_%d.mpc
     echo
     for t in $N
     do
       {
        if [ $t == "0" ]
        then
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_N1.mpc
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_N1.cache
	fi
        if [ $t == "1" ]
        then
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_N2.mpc
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_N2.cache
	fi
        if [ $t == "2" ]
        then
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_S1.mpc
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_S1.cache
	fi
        if [ $t == "3" ]
        then
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc tmp/clouds_${IMAGE_BORDERLESS}_S2.mpc
          mv tmp/clouds_${IMAGE_BORDERLESS}_${t}.cache tmp/clouds_${IMAGE_BORDERLESS}_S2.cache
	fi
       }
     done
    }
   else echo "=> Skipping existing files: tmp/clouds_${IMAGE_BORDERLESS}_[N1-S2].mpc" | tee -a log.txt
   fi
   # 1m, 30s
   getProcessingTime

   echo | tee -a log.txt
   echo "###################################" | tee -a log.txt
   echo "## add ${BORDER_WIDTH}px borders to the tiles ##" | tee -a log.txt
   echo "###################################" | tee -a log.txt
   for t in $TILES
   do
     if [ ! -s "tmp/clouds_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" ]
     then
       convert \
         -monitor \
         tmp/clouds_${IMAGE_BORDERLESS}_${t}.mpc \
         -bordercolor none \
         -border ${BORDER_WIDTH} \
         tmp/clouds_${RESOLUTION_MAX}_${t}_emptyBorder.mpc
       echo
       cp tmp/clouds_${RESOLUTION_MAX}_${t}_emptyBorder.mpc tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc
       cp tmp/clouds_${RESOLUTION_MAX}_${t}_emptyBorder.cache tmp/clouds_seams_${RESOLUTION_MAX}_${t}.cache
     else echo "=> Skipping existing file: tmp/clouds_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" | tee -a log.txt
     fi
   done
   echo
   # 1m, 44s
   getProcessingTime

   echo | tee -a log.txt
   echo "#######################################" | tee -a log.txt
   echo "## propagate last pixels to the edge ##" | tee -a log.txt
   echo "#######################################" | tee -a log.txt

   CROP_TOP="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_RIGHT="1x${IMAGE_BORDERLESS}+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOM="${IMAGE_BORDERLESS}x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
   CROP_LEFT="1x${IMAGE_BORDERLESS}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPLEFT="1x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPRIGHT="1x1+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOMRIGHT="1x1+${IMAGE_WITH_BORDER}+${IMAGE_WITH_BORDER}"
   CROP_BOTTOMLEFT="1x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"

   ## HORIZ meaning a horizontal bar, like the one on top
   HORIZ_RESIZE="${IMAGE_BORDERLESS}x${BORDER_WIDTH}"
   VERT_RESIZE="${BORDER_WIDTH}x${IMAGE_BORDERLESS}"

   POS_TOP="+${BORDER_WIDTH}+0"
   POS_RIGHT="+${IMAGE_WITH_BORDER_POS}+${BORDER_WIDTH}"
   POS_BOTTOM="+${BORDER_WIDTH}+${IMAGE_WITH_BORDER_POS}"
   POS_LEFT="+0+${BORDER_WIDTH}"

   for t in $TILES
   do
     if [ ! -s tmp/clouds_${RESOLUTION_MAX}_${t}_done.mpc ]
     then
     for b in $BORDERS
     do
       {
        if [ $b == "top" ]
        then
          CROP=$CROP_TOP
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_TOP
          CROPCORNER=$CROP_TOPRIGHT
          CORNER_POS="+${IMAGE_WITH_BORDER_POS}+0"
          CORNER_NAME="topRight"
        fi
        if [ $b == "right" ]
        then
          CROP=$CROP_RIGHT
          RESIZE=$VERT_RESIZE
          POSITION=$POS_RIGHT
          CROPCORNER=$CROP_BOTTOMRIGHT
          CORNER_POS="+${IMAGE_WITH_BORDER_POS}+${IMAGE_WITH_BORDER_POS}"
          CORNER_NAME="bottomRight"
        fi
        if [ $b == "bottom" ]
        then
          CROP=$CROP_BOTTOM
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_BOTTOM
          CROPCORNER=$CROP_BOTTOMLEFT
          CORNER_POS="+0+${IMAGE_WITH_BORDER_POS}"
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
        convert \
          -monitor \
          tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc \
          -crop $CROP \
          -resize $RESIZE\! \
          tmp/clouds_${RESOLUTION_MAX}_${t}_seam_${b}.mpc
        convert \
          -monitor \
          tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc \
          -crop $CROPCORNER \
          -resize ${BORDER_WIDTH}x${BORDER_WIDTH}\! \
          tmp/clouds_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc
        convert \
          -monitor \
          tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc \
          tmp/clouds_${RESOLUTION_MAX}_${t}_seam_${b}.mpc \
          -geometry $POSITION \
          -composite \
          tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc
        echo
        convert \
          -monitor \
          tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc \
          tmp/clouds_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc \
          -geometry $CORNER_POS \
          -composite \
          tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc
        echo
       }
     done
     echo
     cp tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc tmp/clouds_${RESOLUTION_MAX}_${t}_done.mpc
     cp tmp/clouds_seams_${RESOLUTION_MAX}_${t}.cache tmp/clouds_${RESOLUTION_MAX}_${t}_done.cache
     else echo "=> Skipping existing file: tmp/clouds_${RESOLUTION_MAX}_${t}_done.mpc" | tee -a log.txt
     fi
   done
   # 2m, 34s
   getProcessingTime

   for t in $TILES
   do
     echo | tee -a log.txt
     echo "#############################" | tee -a log.txt
     echo "## Final output of tile $t ##" | tee -a log.txt
     echo "#############################" | tee -a log.txt
     for r in $RESOLUTION
     do
       {
        if [ $r -eq 16384 ]
          then
            if [ $NO_RESOLUTION_GIVEN == "true" ]
              then
                continue
	      else
	        r=8192
	    fi
	fi
        mkdir -p output/$r
        echo
        echo "--> Writing output/${r}/clouds_${t}.png @ ${r}x${r}" | tee -a log.txt
	convert \
	  -monitor \
	  tmp/clouds_${RESOLUTION_MAX}_${t}_done.mpc \
	  -resize ${r}x${r} \
	  output/${r}/clouds_${t}.png
       }
     done

     echo | tee -a log.txt
     echo "Cloud $t [ done ]" | tee -a log.txt
     echo | tee -a log.txt
   done
   echo "################################" | tee -a log.txt
   echo "####    Clouds: [ done ]    ####" | tee -a log.txt
   echo "################################" | tee -a log.txt

   # 7m, 4s
   #
   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $SECS s" | tee -a log.txt
   prettyTime
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s" | tee -a log.txt

   if [ $BUILDCHECKS == "true" ]
     then
     CHECK="clouds"
     checkResults
   fi
  }

function checkResults
  {
   echo | tee -a log.txt
   echo "##############################################" | tee -a log.txt
   echo "##  Creating a mosaic of the created tiles  ##" | tee -a log.txt
   echo "##############################################" | tee -a log.txt
   echo | tee -a log.txt

   RES=16384
   for r in $RESOLUTION
   do
     if [ $r -le $RES ]
     then
       RES=$r
     fi
   done
   let "WIDTH = 4 * $RES"
   let "HEIGHT = 2 * $RES"
   echo "Lowest available resolution is: $RES" | tee -a log.txt

   if [ $CHECK == "clouds" -o $CHECK == "all" ]
   then
     {
      echo "checking clouds..." | tee -a log.txt
      echo | tee -a log.txt

      echo "Creating canvas ${WIDTH}x${HEIGHT}" | tee -a log.txt
      convert \
        -size ${WIDTH}x${HEIGHT} \
        xc:Black \
        -alpha on \
        check_clouds.png

      POS=0
      for t in 1 2 3 4
      do
        convert \
          -monitor \
          check_clouds.png \
          output/${RES}/clouds_N${t}.png \
          -geometry +${POS}+0 \
          -composite \
          check_clouds.png
        echo
        convert \
          -monitor \
          check_clouds.png \
          output/${RES}/clouds_S${t}.png \
          -geometry +${POS}+${RES} \
          -composite \
          check_clouds.png
        echo
        let "POS += $RES"
      done
      mogrify \
        -monitor \
        -resize 4096x2048 \
        check_clouds.png
     }
   fi

   if [ $CHECK == "world" -o $CHECK == "all" ]
   then
     {
      echo "checking world..." | tee -a log.txt
      echo | tee -a log.txt

      echo "Creating canvas ${WIDTH}x${HEIGHT}" | tee -a log.txt
      convert \
        -size ${WIDTH}x${HEIGHT} \
        xc:Black \
        -alpha on \
        check_world.png

      POS=0
      for t in 1 2 3 4
      do
        convert \
          -monitor \
          check_world.png \
          output/${RES}/world_N${t}.png \
          -alpha Off \
          -geometry +${POS}+0 \
          -composite \
          check_world.png
        echo
        convert \
          -monitor \
          check_world.png \
          output/${RES}/world_S${t}.png \
          -alpha Off \
          -geometry +${POS}+${RES} \
          -composite \
          check_world.png
        echo
        let "POS += $RES"
      done
      mogrify \
        -monitor \
        -resize 4096x2048 \
        check_world.png

      for f in $TILES
      do
        convert \
          -monitor \
          tmp/night_${IMAGE_BORDERLESS}_${f}_neg.mpc \
          -resize 1024x1024 \
          -negate \
          tmp/night_${IMAGE_BORDERLESS}_${f}_check.mpc
      done
      montage \
        -monitor \
        -mode concatenate \
        -tile 4x \
        tmp/night_${IMAGE_BORDERLESS}_??_check.mpc \
        check_night.png
     }
   fi
  }



###############################
####    Actual program:    ####
###############################

echo | tee log.txt
echo "--------------------------------------------------------------" | tee -a log.txt
echo | tee -a log.txt
echo "Processing starts..." | tee -a log.txt
echo | tee -a log.txt
printf "Target:     " | tee -a log.txt
if [ $CLOUDS == "true" ] ; then printf "clouds " | tee -a log.txt ; fi
if [ $WORLD == "true" ] ;  then printf "world " | tee -a log.txt ; fi
echo | tee -a log.txt
echo "Will work in ${RESOLUTION_MAX}x${RESOLUTION_MAX} resolution and will output" | tee -a log.txt
printf "Resolution: " | tee -a log.txt
for r in $RESOLUTION ; do printf "%sx%s " $r $r | tee -a log.txt ; done
echo | tee -a log.txt
echo | tee -a log.txt
echo "--------------------------------------------------------------" | tee -a log.txt
echo | tee -a log.txt

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





echo | tee -a log.txt
echo "convert.sh has finished." | tee -a log.txt
echo | tee -a log.txt
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
