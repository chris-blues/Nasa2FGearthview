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
   if [ $MINUTES -gt 0 ] ; then OUTPUTSTRING="${MINUTES}m, ${SECS}s" ; fi
   if [ $HOURS -gt 0 ] ; then OUTPUTSTRING="${HOURS}h, ${MINUTES}m, ${SECS}s" ; fi
   if [ $DAYS -gt 0 ] ; then OUTPUTSTRING="${DAYS}d, ${HOURS}h, ${MINUTES}m, ${SECS}s" ; fi
   echo "Processing time: $OUTPUTSTRING"
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
   STARTTIME=$(date +%s)
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
       convert \
         -monitor \
         -limit memory 32 \
         -limit map 32 \
         input/dnb_land_ocean_ice.2012.54000x27000_geo.tif \
         tmp/nightlights_54000x27000.mpc
   else echo "=> Skipping existing file: tmp/nightlights_54000x27000.mpc"
   fi
   LASTTIME=$STARTTIME
   # 1m, 59s
   getProcessingTime

   echo
   echo "########################"
   echo "## Resize nightlights ##"
   echo "########################"
   if [ ! -s "tmp/nightlights_64512x32256.mpc" ]
   then
       convert \
         -monitor \
         -limit memory 32 \
         -limit map 32 \
         tmp/nightlights_54000x27000.mpc \
         -resize 64512x32256 \
         tmp/nightlights_64512x32256.mpc
   else echo "=> Skipping existing file: tmp/nightlights_32256x16128.mpc"
   fi
   # 3h, 47m, 29s
   getProcessingTime

   echo
   echo "#############################################"
   echo "## Filter out low colors (continents, ice) ##"
   echo "#############################################"
   if [ ! -s "tmp/nightlights_64512x32256_lowColorsCut.mpc" ]
   then
       convert \
         -monitor \
         -limit memory 32 \
         -limit map 32 \
         tmp/nightlights_64512x32256.mpc \
         -channel R -level 7.8%,100%,1.5 \
         -channel G -level 13.7%,100%,1.5 \
         -channel B -level 33%,100%,1.5 \
         +channel \
         tmp/nightlights_64512x32256_lowColorsCut.mpc
   else echo "=> Skipping existing file: tmp/nightlights_64512x32256_lowColorsCut.mpc"
   fi
   # 1h, 8m, 52s
   getProcessingTime

   echo
   echo "#####################################"
   echo "## cut nightlight image into tiles ##"
   echo "#####################################"
   if [ ! -s "tmp/night_7.mpc" ]
   then
     convert \
       -monitor \
       -limit memory 32 \
       -limit map 32 \
       tmp/nightlights_64512x32256_lowColorsCut.mpc \
       -colorspace Gray \
       -crop 16128x16128 +repage \
       -alpha Off \
       tmp/night_%d.mpc
   else echo "=> Skipping existing files: tmp/night_[0-7].mpc"
   fi
   # 41m, 43s
   getProcessingTime

   echo
   echo "###################"
   echo "## invert colors ##"
   echo "###################"
   for f in $IM
   do
     IM2FG $f
     if [ ! -s "tmp/night_${DEST}_neg.mpc" ]
     then
       convert \
         -monitor \
         tmp/night_${f}.mpc \
         -negate \
         tmp/night_${DEST}_neg.mpc
     else echo "=> Skipping existing file: tmp/night_${DEST}_neg.mpc"
     fi
   done
   # 5m, 33s
   getProcessingTime

   echo
   echo "##############################"
   echo "##  Prepare world textures  ##"
   echo "##############################"
   echo
   echo "##############################################"
   echo "## Resize the NASA-Originals to 16k-(2*128) ##"
   echo "##############################################"
   for t in $NASA
   do
     NASA2FG $t
     if [ ! -s "tmp/world_seamless_16128_${DEST}.mpc" ]
     then
       {
        ## Workaround for tiles N3 and N4 - there's a gray failure area at the top border - let's remove it!
        if [ $t == "C1" ]
        then
          # pick a sample pixel. The polar regions are all equally colored.
          convert \
            -monitor \
            -limit memory 32 \
            -limit map 32 \
            tmp/world_seamless_16128_N2.mpc \
            -crop 1x1+1+1 \
            -resize 16128x1164\! \
            tmp/bluebar.mpc
        fi
        if [ $t == "C1" -o $t == "D1" ]
        then
          {
           # copy the sample over to the tile:
           convert \
             -monitor \
             -limit memory 32 \
             -limit map 32 \
             input/world.200408.3x21600x21600.${t}.png \
             -resize 16128x16128 \
             tmp/bluebar.mpc \
             -geometry +0+0 \
             -composite \
             tmp/world_seamless_16128_${DEST}.mpc
           echo
          }
        else
          {
           convert \
             -monitor \
             -limit memory 32 \
             -limit map 32 \
             input/world.200408.3x21600x21600.${t}.png \
             -resize 16128x16128 \
             tmp/world_seamless_16128_${DEST}.mpc
	  }
	fi
       }
     else echo "=> Skipping existing file: tmp/world_seamless_16128_${DEST}.mpc"
     fi
   done
   # 3h, 12m, 9s
   getProcessingTime

   echo
   echo "##################################################"
   echo "## Merge nightlights into world's alpha channel ##"
   echo "##################################################"
   for t in $TILES
   do
     if [ ! -s "tmp/world_seamless_16128_${t}_composite.mpc" ]
     then
       convert \
         -monitor \
         tmp/world_seamless_16128_${t}.mpc \
         tmp/night_${t}_neg.mpc \
         -compose CopyOpacity \
         -composite \
         tmp/world_seamless_16128_${t}_composite.mpc
     else echo "=> Skipping existing file: tmp/world_seamless_16128_${t}_composite.mpc"
     fi
   done
   # 11m, 26s
   getProcessingTime

   echo
   echo "#####################################"
   echo "## Put a 128px border to each side ##"
   echo "#####################################"
   for t in $TILES
   do
     if [ ! -s "tmp/world_seams_16k_${t}_emptyBorder.mpc" ]
     then
       convert \
         -monitor \
         tmp/world_seamless_16128_${t}_composite.mpc \
         -bordercolor none \
         -border 128 \
         tmp/world_seams_16k_${t}_emptyBorder.mpc
       echo
     fi
     if [ ! -s "tmp/world_seams_16k_${t}.mpc" ]
     then
       cp tmp/world_seams_16k_${t}_emptyBorder.mpc tmp/world_seams_16k_${t}.mpc
       cp tmp/world_seams_16k_${t}_emptyBorder.cache tmp/world_seams_16k_${t}.cache
     else echo "=> Skipping existing file: tmp/world_seams_16k_${t}.mpc"
     fi
   done
   # 11m, 24s
   getProcessingTime

   echo
   echo "######################################################"
   echo "## crop borderline pixels and propagate to the edge ##"
   echo "######################################################"

   CROP_TOP="16128x1+128+128"
   CROP_RIGHT="1x16128+16256+128"
   CROP_BOTTOM="16128x1+128+16256"
   CROP_LEFT="1x16128+128+128"
   CROP_TOPLEFT="1x1+128+128"
   CROP_TOPRIGHT="1x1+16256+128"
   CROP_BOTTOMRIGHT="1x1+16256+16256"
   CROP_BOTTOMLEFT="1x1+128+16256"

   ## HORIZ meaning a horizontal bar, like the one on top
   HORIZ_RESIZE="16128x128"
   VERT_RESIZE="128x16128"

   POS_TOP="+128+0"
   POS_RIGHT="+16256+128"
   POS_BOTTOM="+128+16256"
   POS_LEFT="+0+128"

   for t in $TILES
   do
     if [ ! -s "tmp/world_16k_done_${t}.mpc" ]
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
          CORNER_POS="+16256+0"
          CORNER_NAME="topRight"
        fi
        if [ $b == "right" ]
        then
          CROP=$CROP_RIGHT
          RESIZE=$VERT_RESIZE
          POSITION=$POS_RIGHT
          CROPCORNER=$CROP_BOTTOMRIGHT
          CORNER_POS="+16256+16256"
          CORNER_NAME="bottomRight"
        fi
        if [ $b == "bottom" ]
        then
          CROP=$CROP_BOTTOM
          RESIZE=$HORIZ_RESIZE
          POSITION=$POS_BOTTOM
          CROPCORNER=$CROP_BOTTOMLEFT
          CORNER_POS="+0+16256"
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
	convert \
	  -monitor \
	  tmp/world_seams_16k_${t}_emptyBorder.mpc \
	  -crop $CROP \
	  -resize $RESIZE\! \
	  tmp/world_${t}_seam_${b}.mpc
        convert \
          -monitor \
          tmp/world_seams_16k_${t}_emptyBorder.mpc \
          -crop $CROPCORNER \
          -resize 128x128\! \
          tmp/world_${t}_seam_${CORNER_NAME}.mpc
        convert \
          -monitor \
          tmp/world_seams_16k_${t}.mpc \
          tmp/world_${t}_seam_${b}.mpc \
          -geometry $POSITION \
          -composite \
          tmp/world_seams_16k_${t}.mpc
        echo
        convert \
          -monitor \
          tmp/world_seams_16k_${t}.mpc \
          tmp/world_${t}_seam_${CORNER_NAME}.mpc \
          -geometry $CORNER_POS \
          -composite \
          tmp/world_seams_16k_${t}.mpc
        echo
       }
     done
     echo
     cp -v tmp/world_seams_16k_${t}.mpc tmp/world_16k_done_${t}.mpc
     cp -v tmp/world_seams_16k_${t}.cache tmp/world_16k_done_${t}.cache

     else echo "=> Skipping existing file: tmp/world_16k_done_${t}.mpc"
     fi

  done
  # 37m, 6s
  getProcessingTime

  for t in $TILES
   do
     echo
     echo "#############################"
     echo "## Final output of tile $t ##"
     echo "#############################"
     for r in $RESOLUTION
     do
       {
        mkdir -p output/$r
        echo
        echo "--> Writing output/${r}/world_${t}.dds @ ${r}x${r}"
	env MAGICK_TMPDIR=${PWD}/tmp nice -10 \
	convert \
	  -monitor \
	  tmp/world_16k_done_${t}.mpc \
	  -resize ${r}x${r} \
	  -flip \
	  -define dds:compression=dxt5 \
	  output/${r}/world_${t}.dds
	echo
	echo "--> Writing output/${r}/world_${t}.png @ ${r}x${r}"
	env MAGICK_TMPDIR=${PWD}/tmp nice -10 \
	convert \
	  -monitor \
	  tmp/world_16k_done_${t}.mpc \
	  -resize ${r}x${r} \
	  output/${r}/world_${t}.png
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
   # 2h, 19m, 7s
   # Overall processing time: 44089 s
   # Overall processing time: 0 d, 2 h, 19 m, 7 s

   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then TOTALSECS=0
     else let "TOTALSECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $TOTALSECS s"
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s"

   if [ $BUILDCHECKS == "true" ]
     then
     CHECK="world"
     checkResults
   fi
  }

function generateClouds
  {
   if [ -z $STARTTIME ] ; then STARTTIME=$(date +%s) ; fi
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
       convert \
         -monitor \
         input/cloud.${t}.2001210.21600x21600.png \
         -resize 16128x16128 \
         -alpha copy \
         +level-colors white \
         tmp/cloud.T16k${t}.mpc
     else echo "=> Skipping existing file: tmp/cloud.T16k${t}.mpc"
     fi
   done
   echo
   # 6m, 4s
   LASTTIME=$STARTTIME
   getProcessingTime

   echo
   echo "####################################"
   echo "## cut cloud images into 8k tiles ##"
   echo "####################################"
   if [ ! -s "tmp/clouds_S2.mpc" ]
   then
    {
     convert \
       -monitor \
       tmp/cloud.T16kE.mpc \
       -crop 8064x8064 \
       +repage \
       tmp/clouds_%d.mpc
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
     convert \
       -monitor \
       tmp/cloud.T16kW.mpc \
       -crop 8064x8064 \
       +repage \
       tmp/clouds_%d.mpc
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
   # 1m, 30s
   getProcessingTime

   echo
   echo "###################################"
   echo "## add 64px borders to the tiles ##"
   echo "###################################"
   for t in $TILES
   do
     if [ ! -s "tmp/clouds_${t}_emptyBorder.mpc" ]
     then
       convert \
         -monitor \
         tmp/clouds_${t}.mpc \
         -bordercolor none \
         -border 64 \
         tmp/clouds_${t}_emptyBorder.mpc
       echo
     else echo "=> Skipping existing file: tmp/clouds_${t}_emptyBorder.mpc"
     fi
   done
   echo
   # 1m, 44s
   getProcessingTime

   echo
   echo "#######################################"
   echo "## propagate last pixels to the edge ##"
   echo "#######################################"

   CROP_TOP="8064x1+64+64"
   CROP_RIGHT="1x8064+8128+64"
   CROP_BOTTOM="8064x1+64+8128"
   CROP_LEFT="1x8064+64+64"
   CROP_TOPLEFT="1x1+64+64"
   CROP_TOPRIGHT="1x1+8128+64"
   CROP_BOTTOMRIGHT="1x1+8128+8128"
   CROP_BOTTOMLEFT="1x1+64+8128"

   ## HORIZ meaning a horizontal bar, like the one on top
   HORIZ_RESIZE="8064x64"
   VERT_RESIZE="64x8064"

   POS_TOP="+64+0"
   POS_RIGHT="+8128+64"
   POS_BOTTOM="+64+8128"
   POS_LEFT="+0+64"

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
        convert \
          -monitor \
          tmp/clouds_${t}_emptyBorder.mpc \
          -crop $CROP \
          -resize $RESIZE\! \
          tmp/clouds_${t}_seam_${b}.mpc
        convert \
          -monitor \
          tmp/clouds_${t}_emptyBorder.mpc \
          -crop $CROPCORNER \
          -resize 64x64\! \
          tmp/clouds_${t}_seam_${CORNER_NAME}.mpc
        convert \
          -monitor \
          tmp/clouds_${t}_emptyBorder.mpc \
          tmp/clouds_${t}_seam_${b}.mpc \
          -geometry $POSITION \
          -composite \
          tmp/clouds_${t}_emptyBorder.mpc
        echo
        convert \
          -monitor \
          tmp/clouds_${t}_emptyBorder.mpc \
          tmp/clouds_${t}_seam_${CORNER_NAME}.mpc \
          -geometry $CORNER_POS \
          -composite \
          tmp/clouds_${t}_emptyBorder.mpc
        echo
       }
     done
     echo
   done
   # 2m, 34s
   getProcessingTime

   for t in $TILES
   do
     echo
     echo "#############################"
     echo "## Final output of tile $t ##"
     echo "#############################"
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
        echo "--> Writing output/${r}/clouds_${t}.png @ ${r}x${r}"
	convert \
	  -monitor \
	  tmp/clouds_${t}_emptyBorder.mpc \
	  -resize ${r}x${r} \
	  output/${r}/clouds_${t}.png
       }
     done

     echo
     echo "Cloud $t [ done ]"
     echo
   done
   echo "################################"
   echo "####    Clouds: [ done ]    ####"
   echo "################################"

   # 7m, 4s
   #
   getProcessingTime
   echo
   if [ $STARTTIME -eq $ENDTIME ]
     then TOTALSECS=0
     else let "TOTALSECS = $ENDTIME - $STARTTIME"
   fi
   echo "Overall processing time: $TOTALSECS s"
   echo "Overall processing time: $DAYS d, $HOURS h, $MINUTES m, $SECS s"

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
   echo "Lowest available resolution is: $RES"

   if [ $CHECK == "clouds" -o $CHECK == "all" ]
   then
     {
      echo "checking clouds..."
      echo

      echo "Creating canvas ${WIDTH}x${HEIGHT}"
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
      echo "checking world..."
      echo

      echo "Creating canvas ${WIDTH}x${HEIGHT}"
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
          tmp/night_${f}_neg.mpc \
          -resize 1024x1024 \
          -negate \
          tmp/night_${f}_check.mpc
      done
      montage \
        -monitor \
        -mode concatenate \
        -tile 4x \
        tmp/night_??_check.mpc \
        check_night.png
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
if [ $WORLD == "true" ] ;  then printf "world " ; fi
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
