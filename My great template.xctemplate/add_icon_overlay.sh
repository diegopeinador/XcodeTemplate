
# prerequisites:
#  - imagemagick
#  - ghostscript
#
# an easy way to install them is through homebrew ( http://brew.sh ):
# $ brew update
# $ brew install imagemagick ghostscript

IFS=$'\n'
buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
versionNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}")
PATH=${PATH}:/usr/local/bin

# two params:
# $1 filename of the icon in your code
# $2 filename of the icon in the generated code (as used by ios)
function generateIcon () {
  BASE_IMAGE_NAME=$1
  DEST_IMAGE_NAME=$2

  TARGET_PATH="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/${DEST_IMAGE_NAME}"
  BASE_IMAGE_PATH=$(find ${SRCROOT} -name ${BASE_IMAGE_NAME})
  if [ "${BASE_IMAGE_PATH}x" == "x" ]; then
    #echo "ignoring ${BASE_IMAGE_NAME}"
    return
  fi

  WIDTH=$(identify -format %w "${BASE_IMAGE_PATH}")
  FONT_SIZE=$(echo "$WIDTH * .12" | bc -l)
  cornerBackgroundColor=${ICON_BACKGROUNG_COLOR}
  textColor=${ICON_TEXT_COLOR}
  shadowColor=${ICON_SHADOW_COLOR}
  topText=${ICON_TOP_TEXT}

  if [ "${topText}x" != "x" ];then
    convert -size 256x256 -channel RGBA xc:none -background none -stroke "${shadowColor}" \
    	-draw "stroke-width 1 path 'M 0,0 L 110,0' path 'M 0,0 L 0,110' path 'M 255,255 L 145,255' path 'M 255,255 L 255,145'" \
    	-blur 0x22 shadows.png
    convert -size 256x256 -channel RGBA xc:none -background none -fill "${cornerBackgroundColor}" \
    		\( -stroke none -draw "path 'M 0,0 L 125,0 0,125 Z' path 'M 256,256 L 131,256 256,131 Z' image over 0,0  0,0 'shadows.png'" \) \
    		\( -stroke ${textColor} -draw "stroke-width 1.5 path 'M 119,0 L 0,119' path 'M 135,256 L 256,135" \) corners.png
    convert corners.png -resize ${WIDTH}x${WIDTH} resizedRibbon.png
    convert "${BASE_IMAGE_PATH}" -draw "image over 0,0  0,0 'resizedRibbon.png'" \
        -set option:my:bottom_right '%[fx:w*0.85],%[fx:h*0.85]' -set option:my:top_left '%[fx:w*0.17],%[fx:h*0.17]' \
        \( -fill ${textColor} -pointsize ${FONT_SIZE} -font /Library/Fonts/Montserrat-Bold.ttf \
        -background none label:" ${buildNumber} " +distort SRT '%[fx:w/2],%[fx:h/2] 1 -45 %[my:bottom_right]' \) \
        \( -fill ${textColor} -pointsize ${FONT_SIZE} -font /Library/Fonts/Montserrat-Bold.ttf \
        -background none label:" ${topText} " +distort SRT '%[fx:w/2],%[fx:h/2] 1 -45 %[my:top_left]' \) \
        -layers flatten "${TARGET_PATH}"
  fi

  # cleanup
  rm -f shadows.png
  rm -f corners.png
  rm -f resizedRibbon.png
}

function findIconFiles(){
  JSON_FILE="$(find ${SRCROOT} -name AppIcon.appiconset)/Contents.json"
  JSON_CONTENT=`cat $JSON_FILE | tr -d '\n' | tr '{' '\n'` #one icon per line

  for line in $JSON_CONTENT; do
    ICON_SIZE=`echo $line | cut -d \" -f 4`
    ICON_IDIOM=`echo $line | cut -d \" -f 8`
    ORIG_FILENAME=`echo $line | cut -d \" -f 12`
    ICON_SCALE=`echo $line | cut -d \" -f 16`

    if [ "${ORIG_FILENAME}x" != "x" ]; then
      DESTINATION_FILENAME="AppIcon${ICON_SIZE}"
      if [[ ("${ICON_SCALE}" == "2x" || "${ICON_SCALE}" == "3x") ]]; then
        DESTINATION_FILENAME="${DESTINATION_FILENAME}@${ICON_SCALE}"
      fi
      if [[ "${ICON_IDIOM}" == "ipad" ]]; then
        DESTINATION_FILENAME="${DESTINATION_FILENAME}~ipad"
      fi
      DESTINATION_FILENAME="${DESTINATION_FILENAME}.png"

      echo "generateIcon ${ORIG_FILENAME} ${DESTINATION_FILENAME}"
      generateIcon ${ORIG_FILENAME} ${DESTINATION_FILENAME} # process icon
    fi
  done
}

findIconFiles;
