# yourTubeiOS
yourTube for iOS

iOS / tvOS YouTube client with advanced functionality without any need for API keys. With a combination of web scraping using ONO and some magic ported over from javascript this is a lean and fast wrapper for basic YouTube search, channel / playlist listing, video download and playback.

The tvOS version is much newer and isn't nearly as full featured. In conjunction it uses the browser view controller from http://github.com/jvanakker/tvOSBrowser. These availability notes were taken for that README.

You'll need to redefine the following in Availability.h to build the tvOS target successfully.
```
Availability.h for the AppleTV is located in Xcode>Contents>Developer>Platforms>AppleTVOS.platform>Developer>SDKs>AppleTVOS.sdk>usr>include
Availability.h for the AppleTV Simulator is located in Xcode>Contents>Developer>Platforms>AppleTVSimulator.platform>Developer>SDKs>AppleTVSimulator.sdk>usr>include
```
Change:
```
#define __TVOS_UNAVAILABLE                    __OS_AVAILABILITY(tvos,unavailable)
#define __TVOS_PROHIBITED                     __OS_AVAILABILITY(tvos,unavailable)
```
To:
```
#define __TVOS_UNAVAILABLE_NOTQUITE                    __OS_AVAILABILITY(tvos,unavailable)
#define __TVOS_PROHIBITED_NOTQUITE                     __OS_AVAILABILITY(tvos,unavailable)
```
Do this for Availability.h for both simulator and device if you want to run it on the real hardware.


you can now add the latest beta versions by adding my beta cydia repo to your Cydia sources.

Cydia - > Sources - > Edit - > Add - > http://nitosoft.com/beta2/


==========================================================================================

Some basic notes on this:

the tuyu target in the Xcode app will build now, although to get the full proper experience you need to
build through theos in the command line, building through Xcode was just added to allow non-jailbroken
users to enjoy most of the functionality, downloading mostly works but importing to the music library
will never work through a stock application.

To build you need to edit the main Makefile with your device ip address (THEOS_DEVICE_IP), fire up the terminal, cd into yourTubeiOS and 

make package install

---

Some of the functionality for the iOS version requires a jailbreak. Downloading directly from the iOS version into your music library utilizes JODEBox.dylib which handles importing the media into your music library. The audio files are also run through ffmpeg first to fix the weird streaming format audio files are stored in YouTube, it also bumps the volume due to the fact that most audio files on YouTube have a much lower volume.


Last but not least, if you do repurpose any of this code for yourself, please attribute it. Also, pretty much everything in KBYourTube classes is against YouTube TOS, use wisely :)