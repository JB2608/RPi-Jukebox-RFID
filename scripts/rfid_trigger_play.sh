#!/bin/bash

# Reads the card ID from the command line (see Usage).
# Then attempts to play all files inside a folder with
# the given ID given.
#
# Usage:
# ./rfid_trigger_play.sh -c=1234567890
# or
# ./rfid_trigger_play.sh --cardid=1234567890

# VARIABLES TO CHANGE
# adjust these variables to match your system and configuration

# the absolute path to the folder whjch contains the playlist folders
PATHDATA="/home/pi/Documents/musicbox"
#PATHDATA="/home/micz/Documents/bitbucket/musicbox"

# If you use cards to for example change audio level, mute or stop playing,
# replace the following strings with the ID of the card. For example:
# Using the card ID 1234567890 to set the audio to mute, change this line:
# CMDMUTE="mute"
# to the following:
# CMDMUTE="1234567890"
# Leave everything untouched where you do not use a card.
CMDMUTE="mute"
CMDUP="up"
CMDDOWN="down"
CMDHIGH="high"
CMDLOW="low"
CMDSTOP="stop"

# NO CHANGES BENEATH THIS LINE

# Get args from command line (see Usage above)
for i in "$@"
do
case $i in
    -c=*|--cardid=*)
    CARDID="${i#*=}"
    ;;
esac
done

# If you want to see the CARDID printed, uncomment the following line
# echo CARDID = $CARDID

# Set the date and time of now
NOW=`date +%Y-%m-%d.%H:%M:%S`

# If the input is of 'special' use, don't treat it like a trigger to play audio.
# Special uses are for example volume changes, skipping, muting sound.

if [ "$CARDID" == "$CMDMUTE" ]
then
    # amixer -D pulse sset Master 0%
    amixer sset 'Master' 0%

elif [ "$CARDID" == "$CMDUP" ]
then
    # amixer -D pulse sset Master 10%+
    amixer sset 'Master' 10%+

elif [ "$CARDID" == "$CMDDOWN" ]
then
    # amixer -D pulse sset Master 5%-
    amixer sset 'Master' 10%-

elif [ "$CARDID" == "$CMDHIGH" ]
then
    # amixer -D pulse sset Master 97%
    amixer sset 'Master' 97%

elif [ "$CARDID" == "$CMDLOW" ]
then
    # amixer -D pulse sset Master 60%
    amixer sset 'Master' 60%

elif [ "$CARDID" == "$CMDSTOP" ]
then
    pkill vlc

else
    # We checked if the card was a special command, seems it wasn't.
    # Now we expect it to be a trigger for one or more audio file(s).
    # Let's look at the ID, write a bit of log information and then try to play audio.

    # Expected folder structure:
    #
    # $PATHDATA + /shared/audiofolders/ + $FOLDERNAME 
    # Note: $FOLDERNAME is read from a file inside 'shortcuts'. 
    #       See manual for details
    #
    # Example:
    #
    # $PATHDATA/shared/audiofolders/list1/01track.mp3
    #                                    /what-a-great-track.mp3
    #
    # $PATHDATA/shared/audiofolders/list987/always-will.mp3
    #                                      /be.mp3
    #                                      /playing.mp3
    #                                      /x-alphabetically.mp3
    #
    # $PATHDATA/shared/audiofolders/webradio/filewithURL.txt
	
    # Add info into the log, making it easer to monitor cards
    echo "Card ID '$CARDID' was used at '$NOW'." > $PATHDATA/shared/latestID.txt
	
	# Look for human readable shortcut in folder 'shortcuts'
	# check if CARDID has a text file by the same name - which would contain the human readable folder name
	if [ -f $PATHDATA/shared/shortcuts/$CARDID ]
	then
	    # Read human readable shortcut from file
        FOLDERNAME=`cat $PATHDATA/shared/shortcuts/$CARDID`
        # Add info into the log, making it easer to monitor cards
	    echo "This ID has been used before." >> $PATHDATA/shared/latestID.txt
	else
        # Human readable shortcut does not exists, so create one with the content $CARDID
        # this file can later be edited manually over the samba network
        echo "$CARDID" > $PATHDATA/shared/shortcuts/$CARDID
        FOLDERNAME=$CARDID
        # Add info into the log, making it easer to monitor cards
	    echo "This ID was used for the first time." >> $PATHDATA/shared/latestID.txt
    fi
    # Add info into the log, making it easer to monitor cards
    echo "The shortcut points to audiofolder '$FOLDERNAME'." >> $PATHDATA/shared/latestID.txt
	
	# if a folder $FOLDERNAME exists, play content
    if [ -d $PATHDATA/shared/audiofolders/$FOLDERNAME ]
    then
        # create an empty string for the playlist
        PLAYLIST=""
        
        # loop through all the files found in the folder
        for FILE in $PATHDATA/shared/audiofolders/$FOLDERNAME/*
        do
            # add file path to playlist followed by line break
            PLAYLIST=$PLAYLIST$FILE$'\n'
        done
        
        # write playlist to file using the same name as the folder with ending .m3u
        # wrap $PLAYLIST string in "" to keep line breaks
        echo "$PLAYLIST" > $PATHDATA/playlists/$FOLDERNAME.m3u
        
        # first kill any possible running vlc processn => stop playing audio
        pkill vlc
        
        # now start the command line version of vlc loading the playlist
        # start as a background process (command &) - otherwise the input only works once the playlist finished
        (cvlc $PATHDATA/playlists/$FOLDERNAME.m3u &)
    fi
fi