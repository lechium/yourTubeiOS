# yourTubeiOS
yourTube for iOS


This is a basic attempt to port over https://github.com/lechium/yourTube to iOS. For the initial basic versions, if you can't build this yourself you will need to have some apt-7 strict and openssh installed on your iOS device to get this installed.

This code is a bit of a messy playground for me, and code has been moved around / duplicated alot. This will
be refactored as I find time to do so.

you can now add the latest beta versions by adding my beta cydia repo to your Cydia sources.

Cydia - > Sources - > Edit - > Add - > http://nitosoft.com/beta2/


Steps to install from the pre-included deb package.

1. ssh into your iOS device

    ssh root@yourdevice.local

2. install wget and shell-cmds (optional, you may already have them)

    apt-get install wget shell-cmds -y --force-yes

3. download the deb file

    wget --no-check-certificate https://github.com/lechium/yourTubeiOS/raw/master/com.nito.ytbrowser_1.1-18_iphoneos-arm.deb

4. install the deb file

    dpkg -i com.nito.ytbrowser_1.1-18_iphoneos-arm.deb

5. the previous install will likely fail due to missing depenendencies

    apt-get install -f -y --force-yes

6. kill SpringBoard

    killall -9 SpringBoard

at this point you should have a red play "tuYu" icon somewhere, you should be good to go!

==========================================================================================

Some basic notes on this:

The Xcode Project will NOT build anything, it is solely there for convenient code editing and auto completion. 

To build you need to edit the main Makefile with your device ip address (THEOS_DEVICE_IP), fire up the terminal, cd into yourTubeiOS and 

make package install

---

This cannot and will not EVER work on a stock (non jailbroken) iOS device via sideloading, the downloading and AirPlay code is offloaded into the mobile substrate tweak to prevent any background timeouts and to keep things working without the application running. In conjunction with that, it is literally 100% impossible to import music into the music library without a jailbreak from a 3rd party app or tweak.

