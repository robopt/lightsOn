#!/bin/bash
# lightsOn.sh

#Modified 2014 
# robopt 
# emead006 at gmail com 
# url: https://github.com/robopt/lightsOn

#ORIGINAL
# Copyright (c) 2013 iye.cba at gmail com
# url: https://github.com/iye/lightsOn
# This script is licensed under GNU GPL version 2.0 or above


# Modify these variables if you want this script to detect if Mplayer,
# VLC, Minitube, or Firefox or Chromium Flash Video are Fullscreen and disable
# xscreensaver/kscreensaver and PowerManagement.
is_dimmed=0
dim_brightness=-100
dim_contrast=50
orig_brightness=0
orig_contrast=100
mplayer_detection=1
mplayer_detected=0
vlc_detection=1
firefox_flash_detection=1
chromium_flash_detection=1
minitube_detection=1
ignore_displays=('DFP9')

# Names of programs which, when running, you wish to delay the screensaver.
delay_progs=() # For example ('ardour2' 'gmpc')

# enumerate all the attached screens
displays=""
while read id
do
    displays="$displays $id"
done < <(xvinfo | sed -n 's/^screen #\([0-9]\+\)$/\1/p')


#iterate display names, apply ignore list
displayNames=""
while read id
do
	skip=0
	#check if we should ignore this display
	for ignore in $ignore_displays
	do
		if [ "$id" = "$ignore" ];then
			skip=1
			break
		fi
	done
	if [ "$skip" = "1" ]; then
		logger -i -p info "lightsOn [$$]: Display ignored: " $id
		continue
	fi

	displayNames="$displayNames $id"
	logger -i -p info "lightsOn [$$]: Display found: " $id
	#echo $id
done < <(xrandr --query | grep '\(DFP[0-9]\{1,\}\) connected' | grep -o '\(DFP[0-9]\{1,\}\)'  )


# Detect screensaver been used (xscreensaver, kscreensaver or none)
screensaver=`pgrep -l xscreensaver | grep -wc xscreensaver`
if [ $screensaver -ge 1 ]; then
    screensaver=xscreensaver
else
    screensaver=`pgrep -l kscreensaver | grep -wc kscreensaver`
    if [ $screensaver -ge 1 ]; then
        screensaver=kscreensaver
    else
        screensaver=None
        echo "No screensaver detected"
    fi
fi

checkDelayProgs()
{
    for prog in "${delay_progs[@]}"; do
        if [ `pgrep -lfc "$prog"` -ge 1 ]; then
            echo "Delaying the screensaver because a program on the delay list, \"$prog\", is running..."
            delayScreensaver
            break
        fi	
    done
}

checkFullscreen()
{
    # loop through every display looking for a fullscreen window
    mplayer_detected=0
    for display in $displays
    do
        #get id of active window and clean output
        activ_win_id=`DISPLAY=:0.${display} xprop -root _NET_ACTIVE_WINDOW`
        #activ_win_id=${activ_win_id#*# } #gives error if xprop returns extra ", 0x0" (happens on some distros)
        activ_win_id=${activ_win_id:40:9}

        # Skip invalid window ids (commented as I could not reproduce a case
        # where invalid id was returned, plus if id invalid
        # isActivWinFullscreen will fail anyway.)
        #if [ "$activ_win_id" = "0x0" ]; then
        #     continue
        #fi
	
        # Check if Active Window (the foremost window) is in fullscreen state
        isActivWinFullscreen=`DISPLAY=:0.${display} xprop -id $activ_win_id | grep _NET_WM_STATE_FULLSCREEN`
            if [[ "$isActivWinFullscreen" = *NET_WM_STATE_FULLSCREEN* ]];then
                isAppRunning
                var=$?
                if [[ $var -eq 1 ]];then
		    echo "Delaying the screensaver because a active window on \"${display}\" is fullscreen..."
                    delayScreensaver
                fi
            fi
    done
}





# check if active windows is mplayer, vlc or firefox
#TODO only window name in the variable activ_win_id, not whole line.
#Then change IFs to detect more specifically the apps "<vlc>" and if process name exist

isAppRunning()
{
    #Get title of active window
    activ_win_title=`xprop -id $activ_win_id | grep "WM_CLASS(STRING)"`   # I used WM_NAME(STRING) before, WM_CLASS more accurate.



    # Check if user want to detect Video fullscreen on Firefox, modify variable firefox_flash_detection if you dont want Firefox detection
    if [ $firefox_flash_detection == 1 ];then
        if [[ "$activ_win_title" = *unknown* || "$activ_win_title" = *plugin-container* ]];then
        # Check if plugin-container process is running
            flash_process=`pgrep -l plugin-containe | grep -wc plugin-containe`
            #(why was I using this line avobe? delete if pgrep -lc works ok)
            #flash_process=`pgrep -lc plugin-containe`
            if [[ $flash_process -ge 1 ]];then
                return 1
            fi
        fi
    fi


    # Check if user want to detect Video fullscreen on Chromium, modify variable chromium_flash_detection if you dont want Chromium detection
    if [ $chromium_flash_detection == 1 ];then
        if [[ "$activ_win_title" = *exe* ]];then
        # Check if Chromium/Chrome Flash process is running
            flash_process=`pgrep -lfc ".*((c|C)hrome|chromium).*flashp.*"`
            if [[ $flash_process -ge 1 ]];then
                return 1
            fi
        fi
    fi


    #check if user want to detect mplayer fullscreen, modify variable mplayer_detection
    if [ $mplayer_detection == 1 ];then
        #if [[ "$activ_win_title" = *mplayer* || "$activ_win_title" = *MPlayer* ]];then
            #check if mplayer is running.
            #mplayer_process=`pgrep -l mplayer | grep -wc mplayer`
            mplayer_process=`pgrep -lc mplayer`
            if [ $mplayer_process -ge 1 ]; then
                return 1
            fi
        #fi
    fi


    # Check if user want to detect vlc fullscreen, modify variable vlc_detection
    if [ $vlc_detection == 1 ];then
        if [[ "$activ_win_title" = *vlc* ]];then
            #check if vlc is running.
            #vlc_process=`pgrep -l vlc | grep -wc vlc`
            vlc_process=`pgrep -lc vlc`
            if [ $vlc_process -ge 1 ]; then
                return 1
            fi
        fi
    fi

    # Check if user want to detect minitube fullscreen, modify variable minitube_detection
    if [ $minitube_detection == 1 ];then
        if [[ "$activ_win_title" = *minitube* ]];then
            #check if minitube is running.
            #minitube_process=`pgrep -l minitube | grep -wc minitube`
            minitube_process=`pgrep -lc minitube`
            if [ $minitube_process -ge 1 ]; then
                return 1
            fi
        fi
    fi

return 0
}


delayScreensaver()
{

    # reset inactivity time counter so screensaver is not started
    if [ "$screensaver" == "xscreensaver" ]; then
        xscreensaver-command -deactivate > /dev/null
    elif [ "$screensaver" == "kscreensaver" ]; then
        qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    fi


    #Check if DPMS is on. If it is, deactivate and reactivate again. If it is not, do nothing.
    dpmsStatus=`xset -q | grep -ce 'DPMS is Enabled'`
    if [ $dpmsStatus == 1 ];then
            xset -dpms
            xset dpms
    fi

}

#check if theres a fullscreen app and mplayer
checkBrightness()
{
	mplayer_detected=0
	while read id
	do
		windows="$windows $id"
		isActivWinFullscreen=`DISPLAY=:0.${display} xprop -id $id | grep _NET_WM_STATE_FULLSCREEN`
		if [[ "$isActivWinFullscreen" = *NET_WM_STATE_FULLSCREEN* ]];then
		#isAppRunning
		#mplayer_process=`pgrep -l mplayer | grep -wc mplayer`
		mplayer_process=`pgrep -lc mplayer`
			if [ $mplayer_process -ge 1 ]; then
				mplayer_detected=1
			fi
		fi
	done < <(xprop -root _NET_CLIENT_LIST | grep -Z ',\|#'  |  sed -e 's/, \|# /\r\n/g' | grep '0x')
	#(xwininfo -root -children|sed -e 's/^ *//'|grep -E "^0x"|awk '{ print $1 }')

	if [ $mplayer_detected == 1 ] && [ $is_dimmed == 0 ];then
		for display in $displayNames
		do
			setBrightness $display $dim_brightness
			setContrast $display $dim_contrast
			#aticonfig --set-dispattrib=$display,brightness:-100
			#aticonfig --set-dispattrib=$display,contrast:50
		done
		is_dimmed=1
	elif [ $mplayer_detected == 0 ] && [ $is_dimmed == 1 ];then
		for display in $displayNames
		do
			setBrightness $display $orig_brightness
			setContrast $display $orig_contrast
			#aticonfig --set-dispattrib=$display,brightness:0
			#aticonfig --set-dispattrib=$display,contrast:100
		done
		is_dimmed=0
	fi
}

#set the brightness for a display on an ATI system
setBrightness()
{
	aticonfig --set-dispattrib=$1,brightness:$2
}

#set the contrast for a display on an ATI system
setContrast()
{
	aticonfig --set-dispattrib=$1,contrast:$2
}

#on exit revert to original values
onExit()
{
	for display in $displayNames
	do
		setBrightness $display $orig_brightness
		setContrast $display $orig_contrast
	done
}

delay=$1
# If 1st argument empty, use 50 seconds as default.
if [ -z "$1" ];then
    delay=30
fi

#process arguments
TEMP=`getopt --long -o "t:db:dc:ob:oc:" "$@"`
eval set -- "$TEMP"
while true ; do
    case "$1" in 
	-t )
            delay=$2
            shift 2
        ;;
        -db )
            dim_brightness=$2
            shift 2
        ;;
        -dc )
            dim_contrast=$2
            shift 2
        ;;
        -ob )
            orig_brightness=$2
            shift 2
        ;;
        -oc )
            orig_contrast=$2
            shift 2
        ;;
	*)
            break
        ;;
    esac 
done;

#echo arguments
echo "delay = $delay"
echo "dim brightness = $dim_brightness"
echo "dim contrast = $dim_contrast"
echo "original brightness = $orig_brightness"
echo "original contrast = $orig_contrast"


# If argument is not integer quit.
if [[ $delay = *[^0-9]* ]]; then
    echo "The Argument \"$1\" is not valid, not an integer"
    echo "Please use the time in seconds you want the checks to repeat."
    echo "You want it to be ~10 seconds less than the time it takes your screensaver or DPMS to activate"
    exit 1
fi
trap onExit EXIT


while true
do
    checkDelayProgs
    checkFullscreen
    checkBrightness
    sleep $delay
done

exit 0
