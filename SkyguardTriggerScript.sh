#!/bin/sh
#Author: Sreeram Mutya
#Date: 3/14/2016
#Purpose: Capture the skyguard trigger, copy the new files and delete the old files
#####################################################################################
#this is where our asc files are stored
#File Paths
#####################################################################################
SOURCE_DIR=/tmp/logs/can
DEST_DIR=/mnt/internal_storage/logs/
#use RAM for temporary storage like buffers
TEMP_SKYGUARD_BUFFER=/tmp/skyguard_data
MINIMUM_ASC_FILE_SIZE=1024
SKYGUARD_ON=1
SKYGUARD_TRIGGER=0
THRID_BYTE=$1

#####################################################################################
###starts from here
#0X10ff01D6, Bit20 = 1, - Push Button
#####################################################################################
    if [ ! -d $TEMP_SKYGUARD_BUFFER ]; then
      mkdir $TEMP_SKYGUARD_BUFFER
    fi

    if [ ! -f $TEMP_SKYGUARD_BUFFER/skyguard_data.txt ]; then
      touch $TEMP_SKYGUARD_BUFFER/skyguard_data.txt
    fi

echo "$THRID_BYTE" >> $TEMP_SKYGUARD_BUFFER/skyguard_data.txt

#process the files only once per power cycle
if [[ $SKYGUARD_ON -ne $(head -1 $TEMP_SKYGUARD_BUFFER/skyguard_data.txt) ]]; then
    
    SKYGUARD_TRIGGER=$(( $THRID_BYTE >> 3 & $SKYGUARD_ON))
	
	echo "$SKYGUARD_ON" >> $TEMP_SKYGUARD_BUFFER/skyguard_data.txt
	#write the timstamp, not really needed... remove this line once fully tested
	echo "$(date)" >>  $TEMP_SKYGUARD_BUFFER/skyguard_data.txt

	find $SOURCE_DIR -type f -mmin +1 -name '*.asc' -print0 | xargs -r0 rm --
	
	for file in $SOURCE_DIR/*.asc
        do
        if [ $(cat $file | wc -c) -gt $MINIMUM_ASC_FILE_SIZE ]; then
            cp $file $DEST_DIR
        fi
    done
fi