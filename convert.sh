#!/bin/bash

# convert.sh - a script to convert NASA sattelite images into textures
# for use with FGearthview (orbital rendering)
# Copyright (C) 2016 chris_blues <chris@musicchris.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# v0.12: Chris Ringeval (eatdirt):
# -add normalmapping output + small improvements.
#
# v0.14: Chris Ringeval (eatdirt):
# -add alpha channel as inverse height to normalmap (normalmap binary
# modified, forked from plainrich), allows for changing memory limits
# and resizing method.
#
# v0.15: Chris Ringeval (eatdirt):
# - add support for downloading world textures for a given month. Done
#   by appending the name of the month to the command line. Default is
#   as before, namely August.
# - change the way to make border. Instead of stretching the last
#   pixel, we crop the corresponding part on the neighboring
#   tiles. This prevents the appearance of seams with parallax mapping.
#


VERSION="v0.15"

# make sure the script halts on error
set -e

function showHelp
  {
   echo "Nasa2FGearthview converter script $VERSION"
   echo "https://github.com/chris-blues/Nasa2FGearthview"
   echo
   echo "Usage:"
   echo "./convert.sh [ download no-download world clouds heights"
   echo "               1k 2k 4k 8k 16k cleanup rebuild ]"
   echo
   echo "* Append \"no-download\" to the command to skip the download"
   echo "  process alltogether. Only makes sense if you already got"
   echo "  the necessary data."
   echo "* Append \"world\" to the command to generate the world tiles"
   echo "* Append \"clouds\" to the command to generate cloud tiles"
   echo "* Append \"heights\" to the command to generate height tiles"
   echo "  and the normalmaps needed by EarthView. Notice that you need"
   echo "  the normalmap binary to be installed. You can get it from:"
   echo "  https://github.com/eatdust/normalmap"
   echo "* Append \"all\" to the command to generate all - world, clouds"
   echo "  and heights"
   echo "* Append the size of the tiles (1k, 2k, 4k, 8k, 16k). If you"
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
   echo "  all layers will be built: clouds, heights, world and nightlights."
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
   echo "./convert.sh world 4k"
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
  if [ $ARG == "no-download" ] ; then DOWNLOAD="false" ; echo "Skipping the download process" ; fi
  if [ $ARG == "world" ] ; then WORLD="true" ; fi
  if [ $ARG == "clouds" ] ; then CLOUDS="true" ; fi
  if [ $ARG == "heights" ] ; then HEIGHTS="true" ; fi
  if [ $ARG == "all" ] ; then WORLD="true" ; CLOUDS="true" ; HEIGHTS="true" ; fi
  if [ $ARG == "1k" ] ; then RESOLUTION="1024" ; fi
  if [ $ARG == "2k" ] ; then RESOLUTION="2048" ; fi
  if [ $ARG == "4k" ] ; then RESOLUTION="4096" ; fi
  if [ $ARG == "8k" ] ; then RESOLUTION="8192" ; fi
  if [ $ARG == "16k" ] ; then RESOLUTION="16384" ; fi
  if [ $ARG == "cleanup" ] ; then CLEANUP="true" ; fi
  if [ $ARG == "rebuild" ] ; then REBUILD="true" ; fi
  if [ $ARG == "check" ] ; then BUILDCHECKS="true" ; fi
  if [ $ARG == "January" ] ; then MONTH="01" ; fi
  if [ $ARG == "February" ] ; then MONTH="02" ; fi
  if [ $ARG == "March" ] ; then MONTH="03" ; fi
  if [ $ARG == "April" ] ; then MONTH="04" ; fi
  if [ $ARG == "May" ] ; then MONTH="05" ; fi
  if [ $ARG == "June" ] ; then MONTH="06" ; fi
  if [ $ARG == "July" ] ; then MONTH="07" ; fi
  if [ $ARG == "August" ] ; then MONTH="08" ; fi
  if [ $ARG == "September" ] ; then MONTH="09" ; fi
  if [ $ARG == "October" ] ; then MONTH="10" ; fi
  if [ $ARG == "November" ] ; then MONTH="11" ; fi
  if [ $ARG == "December" ] ; then MONTH="12" ; fi
done
if [ -z $DOWNLOAD ] ; then DOWNLOAD="true" ; fi
if [ -z $WORLD ] ; then WORLD="false" ; fi
if [ -z $CLOUDS ] ; then CLOUDS="false" ; fi
if [ -z $HEIGHTS ] ; then HEIGHTS="false" ; fi
if [ -z $CLEANUP ] ; then CLEANUP="false" ; fi
if [ -z $REBUILD ] ; then REBUILD="false" ; fi
if [ -z $BUILDCHECKS ] ; then BUILDCHECKS="false" ; fi
if [ -z $MONTH ] ; then MONTH="08" ; fi

CHECKWORLD=$WORLD
CHECKCLOUDS=$CLOUDS
CHECKHEIGHTS=$HEIGHTS


########################
## Set some variables ##
########################

DL_LOCATION="NASA"

#allows for using an alternate download method (default to wget)
#DL_METHOD="CURL"
DL_METHOD="WGET"

#if you have a lot of RAM, increasing this, for instance to 64GiB,
#gives a huge speed-up
MEM_LIMIT=512MiB

#more info here: https://imagemagick.org/Usage/filter/nicolas/
#very long
#RESIZE_METHOD="-filter LanczosSharp +remap -distort Resize"
#STRETCH_METHOD="-resize"

#faster
RESIZE_METHOD="-resize"
STRETCH_METHOD="-resize"

mkdir -p tmp
export MAGICK_TMPDIR=${PWD}/tmp
echo "tmp-dir: $MAGICK_TMPDIR"

mkdir -p logs
TIME=$(date +"%Y-%m-%d_%H:%M:%S")
LOGFILE_GENERAL="logs/${TIME}.log"
LOGFILE_TIME="logs/${TIME}.time.log"

#command line gimp plugin from https://github.com/eatdust/normalmap
#higher filters (5x5) create too sharp features (no rescaling, I
#assume earthview do its own normalization). We also put in the alpha
#channel the inverse_height
NORMALBIN="normalmap"
NORMALOPTS="-s 1 -f FILTER_PREWITT_3x3 -a ALPHA_INVERSE_HEIGHT"


#set the upstream path to retrieve the world textures of the selected month
IDWORLD=2004${MONTH}
case $MONTH in
    01)
	IDPATH="73000/73938";;
    02)
	IDPATH="73000/73967";;
    03)
	IDPATH="73000/73992";;
    04)
	IDPATH="74000/74017";;
    05)
	IDPATH="74000/74042";;
    06)
	IDPATH="76000/76487";;
    07)
	IDPATH="74000/74092";;
    08)
	IDPATH="74000/74117";;
    09)
	IDPATH="74000/74142";;
    10)
	IDPATH="74000/74167";;    
    11)
	IDPATH="74000/74192";;
    12)
	IDPATH="74000/74218";;
    *)
        #should not be used but safer
	IDPATH="74000/74117"
        IDWORLD="200408";;
esac    

URLS_WORLD="https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.A1.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.A2.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.B1.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.B2.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.C1.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.C2.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.D1.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/${IDPATH}/world.${IDWORLD}.3x21600x21600.D2.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/79000/79765/dnb_land_ocean_ice.2012.54000x27000_geo.tif"

URLS_CLOUDS="https://eoimages.gsfc.nasa.gov/images/imagerecords/57000/57747/cloud.E.2001210.21600x21600.png
https://eoimages.gsfc.nasa.gov/images/imagerecords/57000/57747/cloud.W.2001210.21600x21600.png"

URLS_HEIGHTS="https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_A1_grey_geo.tif
https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_A2_grey_geo.tif
https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_B1_grey_geo.tif
https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_B2_grey_geo.tif
https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_C1_grey_geo.tif
https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_C2_grey_geo.tif
https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_D1_grey_geo.tif
https://eoimages.gsfc.nasa.gov/images/imagerecords/73000/73934/gebco_08_rev_elev_D2_grey_geo.tif"

if ! [ -x "$(command -v $NORMALBIN)" ]
  then
    if ! [ -x "./${NORMALBIN}" ]
      then
        echo ">>>>>>>>>>>>  Error: $NORMALBIN binary not found! <<<<<<<<<<<<<"
        echo "You can get it from: https://github.com/eatdust/normalmap"
        HEIGHTS="false"
      else
        NORMALBIN="./${NORMALBIN}"
    fi
fi


if [ -z $RESOLUTION ]
  then
    RESOLUTION="1024
2048
4096
8192
16384"
    NO_RESOLUTION_GIVEN="false"
    RESOLUTION_MAX="16384"
fi
if [ -z $RESOLUTION_MAX ] ; then RESOLUTION_MAX=$RESOLUTION ; fi


# B1 generated first as we use it to fix A1, C1 and D1 polar cap
# residuals
NASA="B1
A1
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

    if [ $HEIGHTS == "true" ]
   then
     {
      echo
      echo "#########################################"
      echo "## Removing tmp-files of target heights##"
      echo "#########################################"
      rm tmp/height*
     }
   fi

  }

function cleanUp
  {
   echo
   echo "############################"
   echo "## Removing all tmp-files ##"
   echo "############################"
   rm -rvf tmp/night*
   rm -rvf tmp/world*
   rm -rvf tmp/cloud*
   rm -rvf tmp/height*
   rm -rfv tmp/bluebar*
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
   echo "Processing time: $OUTPUTSTRING" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
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


function TILESAROUND
  {
      if [ $1 == "N1" ] ; then
	  if [ $2 == "left" ] ;  then TILEB="N4" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S1" ; fi
	  if [ $2 == "right" ] ; then TILEB="N2" ; fi
	  if [ $2 == "top" ] ; then TILEB="N1" ; fi
      fi
      if [ $1 == "N2" ] ; then
	  if [ $2 == "left" ] ;  then TILEB="N1" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S2" ; fi
	  if [ $2 == "right" ] ; then TILEB="N3" ; fi
	  if [ $2 == "top" ] ; then TILEB="N2" ; fi
      fi
      if [ $1 == "N3" ] ; then
	  if [ $2 == "left" ] ;  then TILEB="N2" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S3" ; fi
	  if [ $2 == "right" ] ; then TILEB="N4" ; fi
	  if [ $2 == "top" ] ; then TILEB="N3" ; fi
      fi
      if [ $1 == "N4" ] ; then
	  if [ $2 == "left" ] ;  then TILEB="N3" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S4" ; fi
	  if [ $2 == "right" ] ; then TILEB="N1" ; fi
	  if [ $2 == "top" ] ; then TILEB="N4" ; fi
      fi
      if [ $1 == "S1" ] ; then
	  if [ $2 == "top" ] ; then TILEB="N1" ; fi
	  if [ $2 == "right" ] ; then TILEB="S2" ; fi
	  if [ $2 == "left" ] ;  then TILEB="S4" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S1" ; fi
      fi
      if [ $1 == "S2" ] ; then
	  if [ $2 == "top" ] ; then TILEB="N2" ; fi
	  if [ $2 == "right" ] ; then TILEB="S3" ; fi
	  if [ $2 == "left" ] ; then TILEB="S1" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S2" ; fi
      fi
      if [ $1 == "S3" ] ; then
	  if [ $2 == "top" ] ; then TILEB="N3" ; fi
	  if [ $2 == "right" ] ; then TILEB="S4" ; fi
	  if [ $2 == "left" ] ; then TILEB="S2" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S3" ; fi
      fi
      if [ $1 == "S4" ] ; then
	  if [ $2 == "top" ] ; then TILEB="N4" ; fi
	  if [ $2 == "right" ] ; then TILEB="S1" ; fi
	  if [ $2 == "left" ] ; then TILEB="S3" ; fi
	  if [ $2 == "bottom" ] ; then TILEB="S4" ; fi
      fi
  }

function B2B
  {  
      if [ $1 == "top" ] ; then ANTIB="bottom" ; fi
      if [ $1 == "right" ] ; then ANTIB="left" ; fi
      if [ $1 == "bottom" ] ; then ANTIB="top" ; fi
      if [ $1 == "left" ] ; then ANTIB="right" ; fi
      
  }
  
function downloadImages
  {
   echo | tee -a $LOGFILE_GENERAL
   echo "###################################################" | tee -a $LOGFILE_GENERAL
   if [ -z $DL_LOCATION ]
   then
       DL_LOCATION="NASA"
   fi

   if [ $DL_LOCATION == "NASA" ]
   then
       echo "## Downloading images from visibleearth.nasa.gov ##" | tee -a $LOGFILE_GENERAL
   fi

   echo "###################################################" | tee -a $LOGFILE_GENERAL

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

   if [ $HEIGHTS == "true" ]
   then
     if [ $DL_LOCATION == "NASA" ]
     then
       downloadHeights
     fi
   fi
  }

function downloadWorld
  {
   mkdir -p input
   echo "Downloading world tiles..." | tee -a $LOGFILE_GENERAL
   for f in $URLS_WORLD
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     echo
     echo "downloading $FILENAME..." | tee -a $LOGFILE_GENERAL
     sleep $[ ( $RANDOM % 10 )  + 1 ]s
     if [ $DL_METHOD == "CURL" ]; then
	 curl --progress-bar -C - --output ./input/$FILENAME -O $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     else
	 wget --wait=10 --random-wait --output-document=input/$FILENAME \
	      --continue --show-progress $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     fi
   done
  }


function downloadHeights
  {
   mkdir -p input
   echo "Downloading height tiles..." | tee -a $LOGFILE_GENERAL
   for f in $URLS_HEIGHTS
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     echo
     echo "downloading $FILENAME..." | tee -a $LOGFILE_GENERAL
     sleep $[ ( $RANDOM % 10 )  + 1 ]s
     if [ $DL_METHOD == "CURL" ]; then
	 curl --progress-bar -C - --output ./input/$FILENAME -O $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     else
	 wget --wait=10 --random-wait --output-document=input/$FILENAME \
	      --continue --show-progress $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     fi     
   done
  }


function downloadClouds
  {
   mkdir -p input
   echo "Downloading cloud tiles..." | tee -a $LOGFILE_GENERAL
   for f in $URLS_CLOUDS
   do
     FILENAME=$(echo $f | sed 's@.*/@@')
     echo
     echo "downloading $FILENAME..." | tee -a $LOGFILE_GENERAL
     sleep $[ ( $RANDOM % 10 )  + 1 ]s
     if [ $DL_METHOD == "CURL" ]; then
	 curl --progress-bar -C - --output ./input/$FILENAME -O $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     else
	 wget --wait=10 --random-wait --output-document=input/$FILENAME \
	      --continue --show-progress $f | tee -a $LOGFILE_GENERAL 2>> $LOGFILE_GENERAL
     fi     
   done
  }

function generateWorld
  {
   STARTTIME=$(date +%s)
   echo | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo "####    Processing World    ####" | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL
#this settings are local to earch generateXXXX
   let "BORDER_WIDTH = $RESOLUTION_MAX / 128"
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - $BORDER_WIDTH"
   
   mkdir -p tmp
   mkdir -p output

   echo | tee -a $LOGFILE_GENERAL
   echo "############################" | tee -a $LOGFILE_GENERAL
   echo "##  Prepare night lights  ##" | tee -a $LOGFILE_GENERAL
   echo "############################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL
   echo "########################################" | tee -a $LOGFILE_GENERAL
   echo "## Convert to a more efficient format ##" | tee -a $LOGFILE_GENERAL
   echo "########################################" | tee -a $LOGFILE_GENERAL
   if [ ! -s "tmp/nightlights_54000x27000.mpc" ]
   then
     # set -x
       convert \
         -monitor \
         -limit memory ${MEM_LIMIT} \
         -limit map ${MEM_LIMIT} \
         input/dnb_land_ocean_ice.2012.54000x27000_geo.tif \
         tmp/nightlights_54000x27000.mpc
     set +x
   else echo "=> Skipping existing file: tmp/nightlights_54000x27000.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
   fi
   echo "input/dnb_land_ocean_ice.2012.54000x27000_geo.tif -> tmp/nightlights_54000x27000.mpc" >> $LOGFILE_TIME
   LASTTIME=$STARTTIME
   # 1m, 59s
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "########################" | tee -a $LOGFILE_GENERAL
   echo "## Resize nightlights ##" | tee -a $LOGFILE_GENERAL
   echo "########################" | tee -a $LOGFILE_GENERAL
   let "RESIZE_W = ( $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH ) ) * 4"
   let "RESIZE_H = ( $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH ) ) * 2"
   if [ ! -s "tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc" ]
   then
     for r in $RESOLUTION
     do
       if [ $r -le $RESOLUTION_MAX ]
       then continue
       fi
       let "IMAGE_SIZE = $r - ( 2 * ( $r / 128 ) )"
       let "I_W = $IMAGE_SIZE * 4"
       let "I_H = $IMAGE_SIZE * 2"
       if [ -s tmp/nightlights_${I_W}x${I_H}.mpc ]
       then
         if [ $I_W -ge $RESIZE_W ]
         then
           echo "--> Found tmp/nightlights_${I_W}x${I_H}.mpc : usable for ${RESOLUTION_MAX}x${RESOLUTION_MAX}" >> $LOGFILE_GENERAL
           FOUND_BIGGER_PICTURE="true"
           TIMESAVER_SIZE="$IMAGE_SIZE"
         fi
       else
         echo "--> No." >> $LOGFILE_GENERAL
       fi
     done
     echo
     if [ -z $FOUND_BIGGER_PICTURE ]
     then
       echo "No suitable image found. Using NASA original..."
       # set -x
       convert \
         -monitor \
         -limit memory ${MEM_LIMIT} \
         -limit map ${MEM_LIMIT} \
         tmp/nightlights_54000x27000.mpc \
         ${RESIZE_METHOD} ${RESIZE_W}x${RESIZE_H}\! \
         tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc
       set +x
     else
       let "I_W = $TIMESAVER_SIZE * 4"
       let "I_H = $TIMESAVER_SIZE * 2"
       echo "==> Timesaver:) Using existing file: tmp/nightlights_${I_W}x${I_H}.mpc" | tee -a $LOGFILE_GENERAL
       # set -x
       convert \
         -monitor \
         -limit memory ${MEM_LIMIT} \
         -limit map ${MEM_LIMIT} \
         tmp/nightlights_${I_W}x${I_H}.mpc \
         ${RESIZE_METHOD} ${RESIZE_W}x${RESIZE_H}\! \
         tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc
       set +x
     fi
   else echo "=> Skipping existing file: tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
   fi
   # 3h, 47m, 29s
   echo "-> tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "#############################################" | tee -a $LOGFILE_GENERAL
   echo "## Filter out low colors (continents, ice) ##" | tee -a $LOGFILE_GENERAL
   echo "#############################################" | tee -a $LOGFILE_GENERAL
   if [ ! -s "tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc" ]
   then
     # set -x
       convert \
         -monitor \
         -limit memory ${MEM_LIMIT} \
         -limit map ${MEM_LIMIT} \
         tmp/nightlights_${RESIZE_W}x${RESIZE_H}.mpc \
         -channel R -level 7.8%,100%,1.5 \
         -channel G -level 13.7%,100%,1.5 \
         -channel B -level 33%,100%,1.5 \
         +channel \
         tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc
     set +x
   else echo "=> Skipping existing file: tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
   fi
   # 1h, 8m, 52s
   echo "-> tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "#####################################" | tee -a $LOGFILE_GENERAL
   echo "## cut nightlight image into tiles ##" | tee -a $LOGFILE_GENERAL
   echo "#####################################" | tee -a $LOGFILE_GENERAL
   if [ ! -s "tmp/night_${IMAGE_BORDERLESS}_7.mpc" ]
   then
     # set -x
     convert \
       -monitor \
       -limit memory ${MEM_LIMIT} \
       -limit map ${MEM_LIMIT} \
       tmp/nightlights_${RESIZE_W}x${RESIZE_H}_lowColorsCut.mpc \
       -crop ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} +repage \
       -alpha Off \
       tmp/night_${IMAGE_BORDERLESS}_%d.mpc
     set +x
   else echo "=> Skipping existing files: tmp/night_${IMAGE_BORDERLESS}_[0-7].mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
   fi
   # 41m, 43s
   echo "-> tmp/night_${IMAGE_BORDERLESS}_[0-7].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "###################" | tee -a $LOGFILE_GENERAL
   echo "## invert colors ##" | tee -a $LOGFILE_GENERAL
   echo "###################" | tee -a $LOGFILE_GENERAL
   for f in $IM
   do
     IM2FG $f
     if [ ! -s "tmp/night_${IMAGE_BORDERLESS}_${DEST}_neg.mpc" ]
     then
       # set -x
       convert \
         -monitor \
         tmp/night_${IMAGE_BORDERLESS}_${f}.mpc \
         -negate \
         tmp/night_${IMAGE_BORDERLESS}_${DEST}_neg.mpc
       set +x
     else echo "=> Skipping existing file: tmp/night_${IMAGE_BORDERLESS}_${DEST}_neg.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 5m, 33s
   echo "-> tmp/night_${IMAGE_BORDERLESS}_[NS][1-4]_neg.mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "##############################" | tee -a $LOGFILE_GENERAL
   echo "##  Prepare world textures  ##" | tee -a $LOGFILE_GENERAL
   echo "##############################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL
   echo "################################################" | tee -a $LOGFILE_GENERAL
   echo "## Resize the NASA-Originals to ${RESOLUTION_MAX}-(2*${BORDER_WIDTH}) ##" | tee -a $LOGFILE_GENERAL
   echo "################################################" | tee -a $LOGFILE_GENERAL
   for t in $NASA
   do
     NASA2FG $t
     FOUND_BIGGER_WORLD_PICTURE="false"
     unset TIMESAVER_SIZE
     if [ ! -s "tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" ]
     then
       {
        for r in 16384 8192 4096 2048
        do
          if [ $r -le $RESOLUTION_MAX ]
          then
            continue
          fi
          let "IMAGE_SIZE = $r - ( 2 * ( $r / 128 ) )"
          let "I_W = $IMAGE_SIZE * 4"
          let "I_H = $IMAGE_SIZE * 2"
          if [ -s tmp/world_seamless_${IMAGE_SIZE}_${DEST}.mpc ]
          then
            if [ $IMAGE_SIZE -ge $IMAGE_BORDERLESS ]
            then
              FOUND_BIGGER_WORLD_PICTURE="true"
              TIMESAVER_SIZE="$IMAGE_SIZE"
            fi
          fi
        done
        if [ $FOUND_BIGGER_WORLD_PICTURE != "true" ]
        then
           ## Workaround for tiles N1, N3 and N4 - there's a gray
           ## failure area at the top border coming from the polar cap
           ## and we remove it! We use N2 map (B1) to pick the pixel,
           ## this has to be generated first
           if [ $t == "A1" ]
           then
             # pick a sample pixel. The polar regions are all equally colored.
             let "OVERLAY_HEIGHT = ${RESOLUTION_MAX} / 14"
             # set -x
             convert \
               -monitor \
               -limit memory ${MEM_LIMIT} \
               -limit map ${MEM_LIMIT} \
               tmp/world_seamless_${IMAGE_BORDERLESS}_N2.mpc \
               -crop 1x1+1+1 \
               ${STRETCH_METHOD} ${IMAGE_BORDERLESS}x${OVERLAY_HEIGHT}\! \
               tmp/bluebar.mpc
             # we overwrite the already generated N2 (B1) to add the bluebar also there	     
	     convert \
                -monitor \
                -limit memory ${MEM_LIMIT} \
                -limit map ${MEM_LIMIT} \
                input/world.${IDWORLD}.3x21600x21600.B1.png \
                ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
                tmp/bluebar.mpc \
                -geometry +0+0 \
                -composite \
                tmp/world_seamless_${IMAGE_BORDERLESS}_N2.mpc
             set +x
           fi
           if [ $t == "C1" -o $t == "D1" -o $t == "A1" ]
           then
             {
              # copy the sample over to the tile:
              # set -x
              convert \
                -monitor \
                -limit memory ${MEM_LIMIT} \
                -limit map ${MEM_LIMIT} \
                input/world.${IDWORLD}.3x21600x21600.${t}.png \
                ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
                tmp/bluebar.mpc \
                -geometry +0+0 \
                -composite \
                tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
              set +x
              echo
             }
             #B1 lands here first
           else
             {
              # set -x
              convert \
                -monitor \
                -limit memory ${MEM_LIMIT} \
                -limit map ${MEM_LIMIT} \
                input/world.${IDWORLD}.3x21600x21600.${t}.png \
                ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
                tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
              set +x
              }
           fi
          else
          echo "==> Timesaver:) Using existing file: tmp/world_seamless_${TIMESAVER_SIZE}_${DEST}.mpc -> tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL
          set -x
          convert \
            -monitor \
            -limit memory ${MEM_LIMIT} \
            -limit map ${MEM_LIMIT} \
             tmp/world_seamless_${TIMESAVER_SIZE}_${DEST}.mpc \
            ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
             tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
          set +x
        fi
       }
     else echo "=> Skipping existing file: tmp/world_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 3h, 12m, 9s
   echo "input/world.${IDWORLD}.3x21600x21600.[A-D][12].png -> tmp/world_seamless_${IMAGE_BORDERLESS}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "##################################################" | tee -a $LOGFILE_GENERAL
   echo "## Merge nightlights into world's alpha channel ##" | tee -a $LOGFILE_GENERAL
   echo "##################################################" | tee -a $LOGFILE_GENERAL
   for t in $TILES
   do
     if [ ! -s "tmp/world_seamless_${IMAGE_BORDERLESS}_${t}_composite.mpc" ]
     then
       # set -x
       convert \
         -monitor -alpha off \
         tmp/world_seamless_${IMAGE_BORDERLESS}_${t}.mpc \
         tmp/night_${IMAGE_BORDERLESS}_${t}_neg.mpc \
         -compose CopyOpacity \
         -composite \
         tmp/world_seamless_${IMAGE_BORDERLESS}_${t}_composite.mpc
       set +x
     else echo "=> Skipping existing file: tmp/world_seamless_${IMAGE_BORDERLESS}_${t}_composite.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 11m, 26s
   echo "-> tmp/world_seamless_${IMAGE_BORDERLESS}_[NS][1-4]_composite.mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "#####################################" | tee -a $LOGFILE_GENERAL
   echo "## Put a ${BORDER_WIDTH}px border to each side ##" | tee -a $LOGFILE_GENERAL
   echo "#####################################" | tee -a $LOGFILE_GENERAL
   for t in $TILES
   do
     if [ ! -s "tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" ]
     then
       # set -x
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
       # set -x
       cp tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc
       cp tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.cache tmp/world_seams_${RESOLUTION_MAX}_${t}.cache
       set +x
     else echo "=> Skipping existing file: tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 11m, 24s
   echo "-> tmp/world_seams_${RESOLUTION_MAX}_[NS][1-4]_emptyBorder.mpc -> tmp/world_seams_${RESOLUTION_MAX}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "######################################################" | tee -a $LOGFILE_GENERAL
   echo "## crop borderline pixels from neighbouring tiles   ##" | tee -a $LOGFILE_GENERAL
   echo "######################################################" | tee -a $LOGFILE_GENERAL

   CROP_TOP="${IMAGE_BORDERLESS}x${BORDER_WIDTH}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_RIGHT="${BORDER_WIDTH}x${IMAGE_BORDERLESS}+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOM="${IMAGE_BORDERLESS}x${BORDER_WIDTH}+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
   CROP_LEFT="${BORDER_WIDTH}x${IMAGE_BORDERLESS}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPLEFT="1x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPRIGHT="1x1+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOMRIGHT="1x1+${IMAGE_WITH_BORDER}+${IMAGE_WITH_BORDER}"
   CROP_BOTTOMLEFT="1x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}" 


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
        TILESAROUND $t $b
	B2B $b

	if [ $TILEB == $t ]
	then
	    fromb=$b
	else
	    fromb=$ANTIB
	fi


#currently modified tile
        if [ $b == "top" ]
	then
	    POSITION=$POS_TOP
	    CROPCORNER=$CROP_TOPRIGHT
	    CORNER_POS="+${IMAGE_WITH_BORDER_POS}+0"
	    CORNER_NAME="topRight"
	fi
	if [ $b == "right" ]
	then
	    POSITION=$POS_RIGHT
	    CROPCORNER=$CROP_BOTTOMRIGHT
	    CORNER_POS="+${IMAGE_WITH_BORDER_POS}+${IMAGE_WITH_BORDER_POS}"
	    CORNER_NAME="bottomRight"
	fi
	if [ $b == "bottom" ]
	then
	    POSITION=$POS_BOTTOM
	    CROPCORNER=$CROP_BOTTOMLEFT
	    CORNER_POS="+0+${IMAGE_WITH_BORDER_POS}"
	    CORNER_NAME="bottomLeft"
	fi
	if [ $b == "left" ]
	then
	    POSITION=$POS_LEFT
	    CROPCORNER=$CROP_TOPLEFT
	    CORNER_POS="+0+0"
	    CORNER_NAME="topLeft"
	fi

#take the borders from these		       
	if [ $fromb == "top" ]
	then
	    CROP=$CROP_TOP
	fi
	if [ $fromb == "right" ]
	then
	    CROP=$CROP_RIGHT
	fi
	if [ $fromb == "bottom" ]
	then
	    CROP=$CROP_BOTTOM
	fi
	if [ $fromb == "left" ]
	then
	    CROP=$CROP_LEFT
	fi

	
        echo
        # set -x
        convert \
          -monitor \
           tmp/world_seams_${RESOLUTION_MAX}_${TILEB}_emptyBorder.mpc \
          -crop $CROP \
           tmp/world_${RESOLUTION_MAX}_${t}_seam_${b}.mpc
        convert \
          -monitor \
          tmp/world_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
          -crop $CROPCORNER \
          ${STRETCH_METHOD} ${BORDER_WIDTH}x${BORDER_WIDTH}\! \
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
     # set -x
     cp -v tmp/world_seams_${RESOLUTION_MAX}_${t}.mpc tmp/world_${RESOLUTION_MAX}_done_${t}.mpc | tee -a $LOGFILE_GENERAL
     cp -v tmp/world_seams_${RESOLUTION_MAX}_${t}.cache tmp/world_${RESOLUTION_MAX}_done_${t}.cache | tee -a $LOGFILE_GENERAL
     set +x

     else echo "=> Skipping existing file: tmp/world_${RESOLUTION_MAX}_done_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi

  done
  # 37m, 6s
  echo "-> tmp/world_seams_${RESOLUTION_MAX}_[NS][1-4].mpc -> tmp/world_${RESOLUTION_MAX}_done_[NS][1-4].mpc" >> $LOGFILE_TIME
  getProcessingTime

  for t in $TILES
   do
     echo | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     echo "## Final output of tile $t ##" | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        echo
        echo "--> Writing output/${r}/world_${t}.dds @ ${r}x${r}"
        # set -x

        if [ ! -s "output/${r}/world_${t}.dds" ]
        then

          convert \
            -monitor \
             tmp/world_${RESOLUTION_MAX}_done_${t}.mpc \
            ${RESIZE_METHOD} ${r}x${r} \
            -flip \
            -define dds:compression=dxt5 \
             output/${r}/world_${t}.dds
          set +x
          echo

        else echo "=> Skipping existing file: output/${r}/world_${t}.dds" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
        fi

        echo "--> Writing output/${r}/world_${t}.png @ ${r}x${r}"

        if [ ! -s "output/${r}/world_${t}.png" ]
        then

          # set -x
          convert \
            -monitor \
             tmp/world_${RESOLUTION_MAX}_done_${t}.mpc \
            ${RESIZE_METHOD} ${r}x${r} \
             output/${r}/world_${t}.png
          set +x
          echo

        else echo "=> Skipping existing file: output/${r}/world_${t}.png" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME

        fi
       }
     done

     echo | tee -a $LOGFILE_GENERAL
     echo "World $t [ done ]" | tee -a $LOGFILE_GENERAL
     echo | tee -a $LOGFILE_GENERAL

   done
   echo "###############################" | tee -a $LOGFILE_GENERAL
   echo "####    World: [ done ]    ####" | tee -a $LOGFILE_GENERAL
   echo "###############################" | tee -a $LOGFILE_GENERAL
   # 2h, 19m, 7s
   # Overall processing time: 44089 s
   # Overall processing time: 0 d, 2 h, 19 m, 7 s

   echo "-> output/<\$RESOLUTIONS>/world_[NS][1-4].png" >> $LOGFILE_TIME
   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $SECS s" | tee -a $LOGFILE_GENERAL
   prettyTime
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s" | tee -a $LOGFILE_GENERAL
  }

function generateClouds
  {
   if [ -z $STARTTIME ] ; then STARTTIME=$(date +%s) ; fi
   # maximum cloud-tile resolution is 8192, since we have no big enough source files...

   if [[ $NO_RESOLUTION_GIVEN == "true" ]]; then
       if [ $RESOLUTION_MAX -eq 16384 ] ; then RESOLUTION_MAX=8192 ; fi
   fi

   let "BORDER_WIDTH = $RESOLUTION_MAX / 128"
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - $BORDER_WIDTH"
   let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
   let "SIZE = 2 * $IMAGE_BORDERLESS"

   echo | tee -a $LOGFILE_GENERAL
   echo "#################################" | tee -a $LOGFILE_GENERAL
   echo "####    Processing clouds    ####" | tee -a $LOGFILE_GENERAL
   echo "#################################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL

   mkdir -p tmp
   mkdir -p output

   echo "######################################" | tee -a $LOGFILE_GENERAL
   echo "## Resize images to ${SIZE} resolution, ##" | tee -a $LOGFILE_GENERAL
   echo "## copy image to alpha-channel and  ##" | tee -a $LOGFILE_GENERAL
   echo "## paint the canvas white (#FFFFFF) ##" | tee -a $LOGFILE_GENERAL
   echo "######################################" | tee -a $LOGFILE_GENERAL
   CT="E
W"
   for t in $CT
   do
     unset FOUND_BIGGER_CLOUD_PICTURE
     unset TIMESAVER_SIZE
     if [ ! -s "tmp/cloud_T_${SIZE}_${t}.mpc" ]
     then
       for r in 16384 8192 4096 2048
        do
          if [ $r -le $RESOLUTION_MAX ]
          then continue
          fi
          let "IMAGE_SIZE = ( $r - ( 2 * ( $r / 128 ) ) ) * 2"
          echo "Does tmp/cloud_T_${IMAGE_SIZE}_${t}.mpc exist?" >> $LOGFILE_GENERAL
          if [ -s tmp/cloud_T_${IMAGE_SIZE}_${t}.mpc ]
          then
            echo "Yes. Is it usable? ( $IMAGE_SIZE >= $SIZE )" >> $LOGFILE_GENERAL
            if [ $IMAGE_SIZE -ge $SIZE ]
            then
              echo "Yes - use it!" >> $LOGFILE_GENERAL
              FOUND_BIGGER_CLOUD_PICTURE="true"
              TIMESAVER_SIZE="$IMAGE_SIZE"
            else echo "No." >> $LOGFILE_GENERAL
            fi
          else echo "No." >> $LOGFILE_GENERAL
          fi
        done
        if [ -z $FOUND_BIGGER_CLOUD_PICTURE ]
        then
          echo "So we'll have to use the NASA originals." >> $LOGFILE_GENERAL
          # set -x
          convert \
            -monitor \
            input/cloud.${t}.2001210.21600x21600.png \
            ${RESIZE_METHOD} ${SIZE}x${SIZE} \
            -alpha copy \
            -channel RGB +level-colors white \
            tmp/cloud_T_${SIZE}_${t}.mpc
          set +x
        else
          echo "==> Timesaver:) Using existing file: tmp/cloud_T_${TIMESAVER_SIZE}_${t}.mpc" | tee -a $LOGFILE_GENERAL
          # set -x
          convert \
            -monitor \
            tmp/cloud_T_${TIMESAVER_SIZE}_${t}.mpc \
            ${RESIZE_METHOD} ${SIZE}x${SIZE} \
            tmp/cloud_T_${SIZE}_${t}.mpc
          set +x
        fi
     else echo "=> Skipping existing file: tmp/cloud_T_${SIZE}_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   echo
   # 6m, 4s
   if [ -z $LASTTIME ] ; then LASTTIME=$STARTTIME ; fi
   echo "input/cloud.[EW].2001210.21600x21600.png -> tmp/cloud_T_${SIZE}_[EW].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "#################################" | tee -a $LOGFILE_GENERAL
   echo "## cut cloud images into tiles ##" | tee -a $LOGFILE_GENERAL
   echo "#################################" | tee -a $LOGFILE_GENERAL
   if [ ! -s "tmp/clouds_${IMAGE_BORDERLESS}_S2.mpc" ]
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
   else echo "=> Skipping existing files: tmp/clouds_${IMAGE_BORDERLESS}_[N3-S4].mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
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
   else echo "=> Skipping existing files: tmp/clouds_${IMAGE_BORDERLESS}_[N1-S2].mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
   fi
   # 1m, 30s
   echo "-> tmp/clouds_${IMAGE_BORDERLESS}_[0-7].mpc -> tmp/clouds_${IMAGE_BORDERLESS}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "###################################" | tee -a $LOGFILE_GENERAL
   echo "## add ${BORDER_WIDTH}px borders to the tiles ##" | tee -a $LOGFILE_GENERAL
   echo "###################################" | tee -a $LOGFILE_GENERAL
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
     else echo "=> Skipping existing file: tmp/clouds_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   echo
   # 1m, 44s
   echo "-> tmp/clouds_${RESOLUTION_MAX}_[NS][1-4]_emptyBorder.mpc tmp/clouds_seams_${RESOLUTION_MAX}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "#################################################" | tee -a $LOGFILE_GENERAL
   echo "## crop borderline pixels from neighbour tiles ##" | tee -a $LOGFILE_GENERAL
   echo "#################################################" | tee -a $LOGFILE_GENERAL

   if [[ $NO_RESOLUTION_GIVEN == "true" ]]; then
       if [ $RESOLUTION_MAX -eq 16384 ] ; then RESOLUTION_MAX=8192 ; fi
   fi
   let "BORDER_WIDTH = $RESOLUTION_MAX / 128"
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - $BORDER_WIDTH"
   let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
   let "SIZE = 2 * $IMAGE_BORDERLESS"

   CROP_TOP="${IMAGE_BORDERLESS}x${BORDER_WIDTH}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_RIGHT="${BORDER_WIDTH}x${IMAGE_BORDERLESS}+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOM="${IMAGE_BORDERLESS}x${BORDER_WIDTH}+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
   CROP_LEFT="${BORDER_WIDTH}x${IMAGE_BORDERLESS}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPLEFT="1x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPRIGHT="1x1+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOMRIGHT="1x1+${IMAGE_WITH_BORDER}+${IMAGE_WITH_BORDER}"
   CROP_BOTTOMLEFT="1x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"

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
        TILESAROUND $t $b
	B2B $b

	if [ $TILEB == $t ]
	then
	    fromb=$b
	else
	    fromb=$ANTIB
	fi


	 #currently modified tile		      
	if [ $b == "top" ]
	then
	    POSITION=$POS_TOP
	    CROPCORNER=$CROP_TOPRIGHT
	    CORNER_POS="+${IMAGE_WITH_BORDER_POS}+0"
	    CORNER_NAME="topRight"
	fi
	if [ $b == "right" ]
	then
	    POSITION=$POS_RIGHT
	    CROPCORNER=$CROP_BOTTOMRIGHT
	    CORNER_POS="+${IMAGE_WITH_BORDER_POS}+${IMAGE_WITH_BORDER_POS}"
	    CORNER_NAME="bottomRight"
	fi
	if [ $b == "bottom" ]
	then
	    POSITION=$POS_BOTTOM
	    CROPCORNER=$CROP_BOTTOMLEFT
	    CORNER_POS="+0+${IMAGE_WITH_BORDER_POS}"
	    CORNER_NAME="bottomLeft"
	fi
	if [ $b == "left" ]
	then
	    POSITION=$POS_LEFT
	    CROPCORNER=$CROP_TOPLEFT
	    CORNER_POS="+0+0"
	    CORNER_NAME="topLeft"
	fi


	 #take the borders from these		       
	if [ $fromb == "top" ]
	then
	    CROP=$CROP_TOP
	fi
	if [ $fromb == "right" ]
	then
	    CROP=$CROP_RIGHT
	fi
	if [ $fromb == "bottom" ]
	then
	    CROP=$CROP_BOTTOM
	fi
	if [ $fromb == "left" ]
	then
	    CROP=$CROP_LEFT
	fi
	echo



        #set -x
        convert \
          -monitor \
          tmp/clouds_seams_${RESOLUTION_MAX}_${TILEB}.mpc \
          -crop $CROP \
          tmp/clouds_${RESOLUTION_MAX}_${t}_seam_${b}.mpc
        convert \
          -monitor \
          tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc \
          -crop $CROPCORNER \
          ${STRETCH_METHOD} ${BORDER_WIDTH}x${BORDER_WIDTH}\! \
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
        set +x
        echo
       }
     done
     echo
     cp tmp/clouds_seams_${RESOLUTION_MAX}_${t}.mpc tmp/clouds_${RESOLUTION_MAX}_${t}_done.mpc
     cp tmp/clouds_seams_${RESOLUTION_MAX}_${t}.cache tmp/clouds_${RESOLUTION_MAX}_${t}_done.cache
     else echo "=> Skipping existing file: tmp/clouds_${RESOLUTION_MAX}_${t}_done.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 2m, 34s
   echo "-> tmp/clouds_seams_${RESOLUTION_MAX}_[NS][1-4].mpc -> tmp/clouds_${RESOLUTION_MAX}_[NS][1-4]_done.mpc" >> $LOGFILE_TIME
   getProcessingTime

   for t in $TILES
   do
     echo | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     echo "## Final output of tile $t ##" | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r

        if [ ! -s "output/${r}/clouds_${t}.png" ]
        then

          echo "--> Writing output/${r}/clouds_${t}.png @ ${r}x${r}" | tee -a $LOGFILE_GENERAL
          convert \
            -monitor \
             tmp/clouds_${RESOLUTION_MAX}_${t}_done.mpc \
            ${RESIZE_METHOD} ${r}x${r} \
             output/${r}/clouds_${t}.png
          echo

        else echo "=> Skipping existing file: output/${r}/clouds_${t}.png" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
        fi

       }
     done

     echo | tee -a $LOGFILE_GENERAL
     echo "Cloud $t [ done ]" | tee -a $LOGFILE_GENERAL
     echo | tee -a $LOGFILE_GENERAL
   done
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo "####    Clouds: [ done ]    ####" | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL

   # 7m, 4s
   echo "-> output/<\$RESOLUTION>/clouds_[NS][1-4].png" | tee -a $LOGFILE_TIME
   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $SECS s" | tee -a $LOGFILE_GENERAL
   prettyTime
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
  }



function generateHeights
  {
  if [ -z $STARTTIME ] ; then STARTTIME=$(date +%s) ; fi
   echo | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo "####    Processing Heights  ####" | tee -a $LOGFILE_GENERAL
   echo "################################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL

   if [[ $NO_RESOLUTION_GIVEN == "true" ]]; then
       if [ $RESOLUTION_MAX -eq 16384 ] ; then RESOLUTION_MAX=8192 ; fi
   fi

   let "BORDER_WIDTH = $RESOLUTION_MAX / 128"
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - $BORDER_WIDTH"
   let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
   let "SIZE = 2 * $IMAGE_BORDERLESS"

   mkdir -p tmp
   mkdir -p output


   echo "################################################" | tee -a $LOGFILE_GENERAL
   echo "## Resize the NASA-Originals to ${RESOLUTION_MAX}-(2*${BORDER_WIDTH}) ##" | tee -a $LOGFILE_GENERAL
   echo "################################################" | tee -a $LOGFILE_GENERAL
   for t in $NASA
   do
     NASA2FG $t
     FOUND_BIGGER_WORLD_PICTURE="false"
     unset TIMESAVER_SIZE
     if [ ! -s "tmp/heights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" ]
     then
       {
        for r in $RESOLUTION
        do
          if [ $r -le $RESOLUTION_MAX ]
          then
            continue
          fi
          let "IMAGE_SIZE = $r - ( 2 * ( $r / 128 ) )"
          let "I_W = $IMAGE_SIZE * 4"
          let "I_H = $IMAGE_SIZE * 2"
          if [ -s tmp/heights_seamless_${IMAGE_SIZE}_${DEST}.mpc ]
          then
            if [ $IMAGE_SIZE -ge $IMAGE_BORDERLESS ]
            then
              FOUND_BIGGER_WORLD_PICTURE="true"
              TIMESAVER_SIZE="$IMAGE_SIZE"
            fi
          fi
        done
        if [ $FOUND_BIGGER_WORLD_PICTURE != "true" ]
        then
            # set -x
              convert \
                -monitor \
                -limit memory ${MEM_LIMIT} \
                -limit map ${MEM_LIMIT} \
                input/gebco_08_rev_elev_${t}_grey_geo.tif \
                ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
                tmp/heights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
              set +x
        else
          echo "==> Timesaver:) Using existing file: tmp/heights_seamless_${TIMESAVER_SIZE}_${DEST}.mpc -> tmp/heights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL
           set -x
          convert \
            -monitor \
            -limit memory ${MEM_LIMIT} \
            -limit map ${MEM_LIMIT} \
            tmp/heights_seamless_${TIMESAVER_SIZE}_${DEST}.mpc \
            ${RESIZE_METHOD} ${IMAGE_BORDERLESS}x${IMAGE_BORDERLESS} \
            tmp/heights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc
          set +x
        fi
       }
     else echo "=> Skipping existing file: tmp/heights_seamless_${IMAGE_BORDERLESS}_${DEST}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 3h, 12m, 9s
   if [ -z $LASTTIME ] ; then LASTTIME=$STARTTIME ; fi
   echo "input/gebco_08_rev_elev_[A-D][12]_grey_geo.tif -> tmp/heights_seamless_${IMAGE_BORDERLESS}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "#####################################" | tee -a $LOGFILE_GENERAL
   echo "## Put a ${BORDER_WIDTH}px border to each side ##" | tee -a $LOGFILE_GENERAL
   echo "#####################################" | tee -a $LOGFILE_GENERAL
   for t in $TILES
   do
     if [ ! -s "tmp/heights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc" ]
     then
       # set -x
       convert \
         -monitor \
         tmp/heights_seamless_${IMAGE_BORDERLESS}_${t}.mpc \
         -bordercolor none \
         -border ${BORDER_WIDTH} \
         tmp/heights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc
       set +x
       echo
     fi
     if [ ! -s "tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc" ]
     then
       # set -x
       cp tmp/heights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc
       cp tmp/heights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.cache tmp/heights_seams_${RESOLUTION_MAX}_${t}.cache
       set +x
     else echo "=> Skipping existing file: tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi
   done
   # 11m, 24s
   echo "-> tmp/heights_seams_${RESOLUTION_MAX}_[NS][1-4]_emptyBorder.mpc -> tmp/heights_seams_${RESOLUTION_MAX}_[NS][1-4].mpc" >> $LOGFILE_TIME
   getProcessingTime

   echo | tee -a $LOGFILE_GENERAL
   echo "######################################################" | tee -a $LOGFILE_GENERAL
   echo "## crop borderline pixels from neighbouring tiles   ##" | tee -a $LOGFILE_GENERAL
   echo "######################################################" | tee -a $LOGFILE_GENERAL

   if [[ $NO_RESOLUTION_GIVEN == "true" ]]; then
       if [ $RESOLUTION_MAX -eq 16384 ] ; then RESOLUTION_MAX=8192 ; fi
   fi
   let "BORDER_WIDTH = $RESOLUTION_MAX / 128"
   let "IMAGE_BORDERLESS = $RESOLUTION_MAX - ( 2 * $BORDER_WIDTH )"
   let "IMAGE_WITH_BORDER = $RESOLUTION_MAX - $BORDER_WIDTH - $BORDER_WIDTH"
   let "IMAGE_WITH_BORDER_POS = $RESOLUTION_MAX - $BORDER_WIDTH"
   let "SIZE = 2 * $IMAGE_BORDERLESS"

   CROP_TOP="${IMAGE_BORDERLESS}x${BORDER_WIDTH}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_RIGHT="${BORDER_WIDTH}x${IMAGE_BORDERLESS}+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOM="${IMAGE_BORDERLESS}x${BORDER_WIDTH}+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
   CROP_LEFT="${BORDER_WIDTH}x${IMAGE_BORDERLESS}+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPLEFT="1x1+${BORDER_WIDTH}+${BORDER_WIDTH}"
   CROP_TOPRIGHT="1x1+${IMAGE_WITH_BORDER}+${BORDER_WIDTH}"
   CROP_BOTTOMRIGHT="1x1+${IMAGE_WITH_BORDER}+${IMAGE_WITH_BORDER}"
   CROP_BOTTOMLEFT="1x1+${BORDER_WIDTH}+${IMAGE_WITH_BORDER}"
   

   POS_TOP="+${BORDER_WIDTH}+0"
   POS_RIGHT="+${IMAGE_WITH_BORDER_POS}+${BORDER_WIDTH}"
   POS_BOTTOM="+${BORDER_WIDTH}+${IMAGE_WITH_BORDER_POS}"
   POS_LEFT="+0+${BORDER_WIDTH}"

   for t in $TILES
   do
     if [ ! -s "tmp/heights_${RESOLUTION_MAX}_done_${t}.mpc" ]
     then
     for b in $BORDERS
     do
       {
        TILESAROUND $t $b
	B2B $b

        if [ $TILEB == $t ]
	then
	    fromb=$b
	else
	    fromb=$ANTIB
	fi


	#currently modified tile		      
	if [ $b == "top" ]
	then
	    POSITION=$POS_TOP
	    CROPCORNER=$CROP_TOPRIGHT
	    CORNER_POS="+${IMAGE_WITH_BORDER_POS}+0"
	    CORNER_NAME="topRight"
	fi
	if [ $b == "right" ]
	then
	    POSITION=$POS_RIGHT
	    CROPCORNER=$CROP_BOTTOMRIGHT
	    CORNER_POS="+${IMAGE_WITH_BORDER_POS}+${IMAGE_WITH_BORDER_POS}"
	    CORNER_NAME="bottomRight"
	fi
	if [ $b == "bottom" ]
	then
	    POSITION=$POS_BOTTOM
	    CROPCORNER=$CROP_BOTTOMLEFT
	    CORNER_POS="+0+${IMAGE_WITH_BORDER_POS}"
	    CORNER_NAME="bottomLeft"
	fi
	if [ $b == "left" ]
	then
	    POSITION=$POS_LEFT
	    CROPCORNER=$CROP_TOPLEFT
	    CORNER_POS="+0+0"
	    CORNER_NAME="topLeft"
	fi


	#take the borders from these		       
	if [ $fromb == "top" ]
	then
	    CROP=$CROP_TOP
	fi
	if [ $fromb == "right" ]
	then
	    CROP=$CROP_RIGHT
	fi
	if [ $fromb == "bottom" ]
	then
	    CROP=$CROP_BOTTOM
	fi
	if [ $fromb == "left" ]
	then
	    CROP=$CROP_LEFT
	fi
	
        echo
        # set -x
        convert \
          -monitor \
          tmp/heights_seams_${RESOLUTION_MAX}_${TILEB}_emptyBorder.mpc \
          -crop $CROP \
          tmp/heights_${RESOLUTION_MAX}_${t}_seam_${b}.mpc
        convert \
          -monitor \
          tmp/heights_seams_${RESOLUTION_MAX}_${t}_emptyBorder.mpc \
          -crop $CROPCORNER \
          ${STRETCH_METHOD} ${BORDER_WIDTH}x${BORDER_WIDTH}\! \
          tmp/heights_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc
        convert \
          -monitor \
          tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc \
          tmp/heights_${RESOLUTION_MAX}_${t}_seam_${b}.mpc \
          -geometry $POSITION \
          -composite \
          tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc
        echo
        convert \
          -monitor \
          tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc \
          tmp/heights_${RESOLUTION_MAX}_${t}_seam_${CORNER_NAME}.mpc \
          -geometry $CORNER_POS \
          -composite \
          tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc
        set +x
        echo
       }
     done
     echo
     # set -x
     cp -v tmp/heights_seams_${RESOLUTION_MAX}_${t}.mpc tmp/heights_${RESOLUTION_MAX}_done_${t}.mpc | tee -a $LOGFILE_GENERAL
     cp -v tmp/heights_seams_${RESOLUTION_MAX}_${t}.cache tmp/heights_${RESOLUTION_MAX}_done_${t}.cache | tee -a $LOGFILE_GENERAL
     set +x

     else echo "=> Skipping existing file: tmp/heights_${RESOLUTION_MAX}_done_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
     fi

  done
  # 37m, 6s
  echo "-> tmp/heights_seams_${RESOLUTION_MAX}_[NS][1-4].mpc -> tmp/heights_${RESOLUTION_MAX}_done_[NS][1-4].mpc" >> $LOGFILE_TIME
  getProcessingTime

  for t in $TILES
   do
     echo | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL
     echo "## Final output of tile $t ##" | tee -a $LOGFILE_GENERAL
     echo "##       and normalmapping ##" | tee -a $LOGFILE_GENERAL
     echo "#############################" | tee -a $LOGFILE_GENERAL

     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        set +x
        echo
        echo "--> Writing output/${r}/heights_${t}.png @ ${r}x${r}"
        # set -x

        if [ ! -s "output/${r}/heights_${t}.png" ]
        then

          convert \
            -monitor \
             tmp/heights_${RESOLUTION_MAX}_done_${t}.mpc \
            ${RESIZE_METHOD} ${r}x${r} \
             output/${r}/heights_${t}.png
          echo

        else echo "=> Skipping existing file: tmp/heights_${RESOLUTION_MAX}_done_${t}.mpc" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
        fi

        echo "--> Writing output/${r}/normalmap_earth_${t}.png @ ${r}x${r}"
        if [ ! -s "output/${r}/normalmap_earth_${t}.png" ]
        then

          $NORMALBIN $NORMALOPTS output/${r}/heights_${t}.png output/${r}/normalmap_earth_${t}.png

        else echo "=> Skipping existing file: output/${r}/normalmap_earth_${t}.png" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
        fi

        set +x
        echo
       }
     done

     echo | tee -a $LOGFILE_GENERAL
     echo "Heights and Normal $t [ done ]" | tee -a $LOGFILE_GENERAL
     echo | tee -a $LOGFILE_GENERAL

   done
   echo "###############################" | tee -a $LOGFILE_GENERAL
   echo "####    Heights: [ done ]  ####" | tee -a $LOGFILE_GENERAL
   echo "###############################" | tee -a $LOGFILE_GENERAL
   # 2h, 19m, 7s
   # Overall processing time: 44089 s
   # Overall processing time: 0 d, 2 h, 19 m, 7 s

   echo "-> output/<\$RESOLUTIONS>/heights_[NS][1-4].png" >> $LOGFILE_TIME
   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then SECS=0
     else let "SECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $SECS s" | tee -a $LOGFILE_GENERAL
   prettyTime
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s" | tee -a $LOGFILE_GENERAL
  }










function checkResults
  {
   echo | tee -a $LOGFILE_GENERAL
   echo "##############################################" | tee -a $LOGFILE_GENERAL
   echo "##  Creating a mosaic of the created tiles  ##" | tee -a $LOGFILE_GENERAL
   echo "##############################################" | tee -a $LOGFILE_GENERAL
   echo | tee -a $LOGFILE_GENERAL

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
   echo "Lowest available resolution is: $RES" | tee -a $LOGFILE_GENERAL

   if [[ $CHECKCLOUDS == "true" ]]
   then
     {
      echo "checking clouds..." | tee -a $LOGFILE_GENERAL
      echo | tee -a $LOGFILE_GENERAL

      echo "Creating canvas ${WIDTH}x${HEIGHT}" | tee -a $LOGFILE_GENERAL
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


   if [[ $CHECKHEIGHTS == "true" ]]
   then
     {
      echo "checking heights..." | tee -a $LOGFILE_GENERAL
      echo | tee -a $LOGFILE_GENERAL

      echo "Creating canvas ${WIDTH}x${HEIGHT}" | tee -a $LOGFILE_GENERAL
      convert \
        -size ${WIDTH}x${HEIGHT} \
        xc:Black \
        -alpha on \
        check_heights.png

      POS=0
      for t in 1 2 3 4
      do
        convert \
          -monitor \
          check_heights.png \
          output/${RES}/heights_N${t}.png \
          -geometry +${POS}+0 \
          -composite \
          check_heights.png
        echo
        convert \
          -monitor \
          check_heights.png \
          output/${RES}/heights_S${t}.png \
          -geometry +${POS}+${RES} \
          -composite \
          check_heights.png
        echo
        let "POS += $RES"
      done
      mogrify \
        -monitor \
        -resize 4096x2048 \
        check_heights.png
     }
   fi



   if [[ $CHECKWORLD == "true" ]]
   then
     {
      echo "checking world..." | tee -a $LOGFILE_GENERAL
      echo | tee -a $LOGFILE_GENERAL

      echo "Creating canvas ${WIDTH}x${HEIGHT}" | tee -a $LOGFILE_GENERAL
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

echo | tee $LOGFILE_GENERAL
echo "--------------------------------------------------------------" | tee -a $LOGFILE_GENERAL
echo | tee -a $LOGFILE_GENERAL
echo "Processing starts..." | tee -a $LOGFILE_GENERAL | tee $LOGFILE_TIME
echo $TIME | tee -a $LOGFILE_TIME
echo | tee -a $LOGFILE_GENERAL
printf "Target:     " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
if [ $CLOUDS == "true" ] ; then printf "clouds " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME ; fi
if [ $HEIGHTS == "true" ] ; then printf "heights " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME ; fi
if [ $WORLD == "true" ] ;  then printf "world " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME ; fi
echo | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
echo "Will work in ${RESOLUTION_MAX}x${RESOLUTION_MAX} resolution and will output" | tee -a $LOGFILE_GENERAL
printf "Resolution: " | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
for r in $RESOLUTION ; do printf "%sx%s " $r $r | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME ; done
echo | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
echo | tee -a $LOGFILE_GENERAL
echo "--------------------------------------------------------------" | tee -a $LOGFILE_GENERAL | tee -a $LOGFILE_TIME
echo | tee -a $LOGFILE_GENERAL


if [[ $REBUILD == "true" ]] ; then rebuild ; fi
if [[ $DOWNLOAD == "true" ]] ; then downloadImages ; fi
if [[ $WORLD == "true" ]] ;  then generateWorld ; fi
if [[ $CLOUDS == "true" ]] ; then generateClouds ; fi
if [[ $HEIGHTS == "true" ]]; then generateHeights; fi
if [[ $BUILDCHECKS == "true" ]] ; then checkResults ; fi
if [[ $CLEANUP == "true" ]] ; then cleanUp ; fi





echo | tee -a $LOGFILE_GENERAL
echo "convert.sh has finished." | tee -a $LOGFILE_GENERAL
echo | tee -a $LOGFILE_GENERAL
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
