#!/bin/sh
#Author: Sreeram Mutya
#Date: 2/29/2016
#Purpose: Capture the trigger, copy the new files and delete the old files
#####################################################################################
#this is where our asc files are stored
#File Paths
#####################################################################################
SOURCE_DIR=/tmp/logs/can
DEST_DIR=/mnt/internal_storage/logs/
TRIGGER_TIME_STAMPS=/mnt/internal_storage/timestamps
FLGS=/mnt/internal_storage/flags
#use RAM for temporary storage like buffers
TEMP_DTC_BUFFER=/tmp/dtc_buffer
ASCII_OFFSET=48
DTC=0
LINE_COUNT=0
DTC_TRIGGER_FLAG=0
MINIMUM_ASC_FILE_SIZE=1024
#DTC_TRIGGER_RANGE_MIN=811   ; original
#DTC_TRIGGER_RANGE_MAX=8447   ; original, below modified by Pat
DTC_TRIGGER_RANGE_MIN=261
DTC_TRIGGER_RANGE_MAX=99300

#####################################################################################
###starts from here
#####################################################################################
    if [ ! -d $TEMP_DTC_BUFFER ]; then
      mkdir $TEMP_DTC_BUFFER
    fi

    if [ ! -f $TEMP_DTC_BUFFER/dtc_buffer.txt ]; then
      touch $TEMP_DTC_BUFFER/dtc_buffer.txt
    fi

        
if [[ "$(tail -1 $TEMP_DTC_BUFFER/dtc_buffer.txt)" != "TRIGGER_CAPTURED" ]]; then
    #variables
    #These variables map to MDI Display Protocol
    #Bytes 1-6 of 0xFF62DC Message - 
    #you may not find this in our JLG Ultraboom CAN Spec so, Refer JLG EPBC SRD 2.51 Page70

    DTC_FIRST_BYTE=$(($1-$ASCII_OFFSET))

    DTC_SECOND_BYTE=$(($2-$ASCII_OFFSET))

    DTC_THIRD_BYTE=$(($3-$ASCII_OFFSET))
    
    DTC_FOURTH_BYTE=$(($4-$ASCII_OFFSET))
    
    DTC_FIFTH_BYTE=$(($5-$ASCII_OFFSET))
    
    DTC_SIXTH_BYTE=$(($6-$ASCII_OFFSET))

   
    #concatenate all the bytes to form a all DTC's instead of parsing all the bytes by shift operation
    if [  $DTC_FIRST_BYTE -ge  0  ]; then
      DTC="$DTC_FIRST_BYTE"
    fi

    if [ $DTC_SECOND_BYTE -ge  0 ]; then
      DTC="$DTC$DTC_SECOND_BYTE"
    fi 

    if [ $DTC_THIRD_BYTE -ge  0 ]; then
      DTC="$DTC$DTC_THIRD_BYTE"
    fi

    if [ $DTC_FOURTH_BYTE -ge  0 ]; then
      DTC="$DTC$DTC_FOURTH_BYTE"
    fi

    if [ $DTC_FIFTH_BYTE -ge 0 ]; then
      DTC="$DTC$DTC_FIFTH_BYTE"
    fi

    if [ $DTC_SIXTH_BYTE -ge  0 ]; then
      DTC="$DTC$DTC_SIXTH_BYTE"
    fi

    
    LINE_COUNT=$(wc -l $TEMP_DTC_BUFFER/dtc_buffer.txt | cut -d " " -f1)

  #I am using Line Count =1 as a flag to make sure that at least 1 DTC is written
  
  if [[ $LINE_COUNT -ge 1 && $DTC -eq $(head -1 $TEMP_DTC_BUFFER/dtc_buffer.txt) ]]; then

     
     if [[ $(tail -1 $TEMP_DTC_BUFFER/dtc_buffer.txt) != "COMPLETE" && $(tail -1 $TEMP_DTC_BUFFER/dtc_buffer.txt) != "TRIGGER_CAPTURED" ]]; then
     echo "COMPLETE" >> $TEMP_DTC_BUFFER/dtc_buffer.txt
     fi

     if [ ! -d $DEST_DIR ]; then
         mkdir $DEST_DIR
	echo "DEST_DIR directory created"
     fi
     
    
     for dtc_num in $(cat $TEMP_DTC_BUFFER/dtc_buffer.txt)
     do
        if [[ $dtc_num -ge $DTC_TRIGGER_RANGE_MIN && $dtc_num -le $DTC_TRIGGER_RANGE_MAX ]]; then
        #combined trigger condition satisfied
        #perform file processing
           if [ $(tail -1 $TEMP_DTC_BUFFER/dtc_buffer.txt) = "COMPLETE" ]; then
           echo "TRIGGER_CAPTURED" >>  $TEMP_DTC_BUFFER/dtc_buffer.txt
           fi

           echo "finding files that are older and deleting them"
           find $SOURCE_DIR -type f -mmin +1 -name '*.asc' -print0 | xargs -r0 rm --
        
           for file in $SOURCE_DIR/*.asc
           do
             if [ $(cat $file | wc -c) -gt $MINIMUM_ASC_FILE_SIZE ]; then
                  cp $file $DEST_DIR
             fi
           done
	fi
     done
  
  elif [[ $DTC -ne 0 ]]; then

    if [[ $LINE_COUNT -eq 0 ]]; then
       echo $DTC >> $TEMP_DTC_BUFFER/dtc_buffer.txt
  
    elif [[ $DTC -ne $( tail -1 $TEMP_DTC_BUFFER/dtc_buffer.txt ) ]]; then
       echo $DTC >> $TEMP_DTC_BUFFER/dtc_buffer.txt
    fi
  fi

elif [ "$(tail -1 $TEMP_DTC_BUFFER/dtc_buffer.txt)" = "COMPLETE" ]; then
  cat /dev/null > $TEMP_DTC_BUFFER/dtc_buffer.txt
fi