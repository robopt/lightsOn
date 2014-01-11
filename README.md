## lightsOn

A bash script that prevents the screensaver and display power management (DPMS) from being activated when you are watching flash videos fullscreen in Firefox or Chromium. It can detect mplayer, minitube, and VLC when they are fullscreen too. Also, screensaver can be prevented when certain specified programs are running. `lightsOn.sh` needs `xscreensaver` or `kscreensaver` to work.

## Usage

Start the script with the number of seconds you want the checks for fullscreen to be done. 

For example,
    
    ./lightsOn.sh 120 & 
    
will Check every 120 seconds if Mplayer, Minitube  VLC, Firefox or Chromium are fullscreen and delay screensaver and Power Management if so. You want the number of seconds to be ~10 seconds less than the time it takes your screensaver or Power Management to activate. If you don't pass an argument, the checks are done every 50 seconds.

An optional array variable exists here to add the names of programs that will delay the screensaver if they're running. This can be useful if you want to maintain a view of the program from a distance, like a music playlist for DJing, or if the screensaver eats up CPU that chops into any background processes you have running, such as realtime music programs like Ardour in MIDI keyboard mode. If you use this feature, make sure you use the name of the binary of the program (which may exist, for instance, in `/usr/bin`).

## Changelog

#### January 11, 2014
- (robopt): added dimming
- (robopt): added display ignore list
- (robopt): added arguments (-t, -db, -dc, -ob, -oc)
- (robopt): added syslog logging

## Todo
- Detect which window is fullscreen (currently any window fullscreen + a running whitelist process)
- Fix arguments since they dont actually work 
