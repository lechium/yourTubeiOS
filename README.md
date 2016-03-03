# yourTubeiOS
yourTube for iOS


This is a basic attempt to port over https://github.com/lechium/yourTube to iOS. For the initial versions, if you can't build this yourself you will need to have apt-7 strict and openssh installed on your iOS device to get this installed.

This code is a bit of a messy playground for me, and code has been moved around / duplicated alot. This will
be refactored as I find time to do so.

you can now add the latest beta versions by adding my beta cydia repo to your Cydia sources.

Cydia - > Sources - > Edit - > Add - > http://nitosoft.com/beta2/


==========================================================================================

Some basic notes on this:

the tuyu target in the Xcode app will build now, although to get the full proper experience you need to
build through theos in the command line, building through Xcode was just added to allow non-jailbroken
users to enjoy some of the functionality, download does not work yet, and importing to the music library
will never work through a stock application.

To build you need to edit the main Makefile with your device ip address (THEOS_DEVICE_IP), fire up the terminal, cd into yourTubeiOS and 

make package install

---

This cannot and will not EVER work on a stock (non jailbroken) iOS device via sideloading, the downloading and AirPlay code is offloaded into the mobile substrate tweak to prevent any background timeouts and to keep things working without the application running. In conjunction with that, it is literally 100% impossible to import music into the music library without a jailbreak from a 3rd party app or tweak.


Last but not least, if you do repurpose any of this code for yourself, please attribute it. Also, pretty much everything in KBYourTube classes is against YouTube TOS, use wisely :)