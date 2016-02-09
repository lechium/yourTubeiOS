# yourTubeiOS
yourTube for iOS


This is a basic attempt to port over https://github.com/lechium/yourTube to iOS. For the initial basic versions, if you can't build this yourself you will need to have some apt-7 strict and openssh installed on your iOS device to get this installed.

This code is a bit of a messy playground for me, and code has been moved around / duplicated alot. This will
be refactored as I find time to do so.

you can now add the latest beta versions by adding my beta cydia repo to your Cydia sources.

Cydia - > Sources - > Edit - > Add - > http://nitosoft.com/beta2/


==========================================================================================

Some basic notes on this:

The Xcode Project will NOT build anything, it is solely there for convenient code editing and auto completion. 

To build you need to edit the main Makefile with your device ip address (THEOS_DEVICE_IP), fire up the terminal, cd into yourTubeiOS and 

make package install

---

This cannot and will not EVER work on a stock (non jailbroken) iOS device via sideloading, the downloading and AirPlay code is offloaded into the mobile substrate tweak to prevent any background timeouts and to keep things working without the application running. In conjunction with that, it is literally 100% impossible to import music into the music library without a jailbreak from a 3rd party app or tweak.

