export ARCHS = armv7 armv7s arm64
TARGET = iphone:8.4
include theos/makefiles/common.mk
THEOS_DEVICE_IP=other-ipod.local
#THEOS_DEVICE_IP=kbphone.local
export GO_EASY_ON_ME=1
export DEBUG=1
#export THEOS_DEVICE_IP=kbphone.local

TWEAK_NAME = YTBrowser
YTBrowser_FILES = YTBrowser.xm YTBrowserHelper.mm
#YTBrowser_FILES += GCDWebServer/GCDWebServer.m GCDWebServer/GCDWebServerConnection.m GCDWebServer/GCDWebServerFunctions.m GCDWebServer/GCDWebServerRequest.m GCDWebServer/GCDWebServerResponse.m


#YTBrowser_FILES += GCDWebServer/GCDWebServerDataRequest.m GCDWebServer/GCDWebServerFileRequest.m GCDWebServer/GCDWebServerMultiPartFormRequest.m GCDWebServer/GCDWebServerURLEncodedFormRequest.m


#YTBrowser_FILES += GCDWebServer/GCDWebServerDataResponse.m GCDWebServer/GCDWebServerErrorResponse.m GCDWebServer/GCDWebServerFileResponse.m GCDWebServer/GCDWebServerStreamedResponse.m

YTBrowser_CXXFLAGS += -fobjc-arc
YTBrowser_CFLAGS += -fobjc-arc

YTBrowser_LDFLAGS = -undefined dynamic_lookup -framework Foundation -framework StoreServices -framework AppSupport -FFrameworks -F/Applications/Xcode7.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk/System/Library/PrivateFrameworks -framework MusicLibrary -IFrameworks -I/Frameworks/GCDWebServers.framework/Headers -IGCDWebServer/Core -IGCDWebServer/Requests -IGCDWebServer/Responses
 
include $(FW_MAKEDIR)/tweak.mk


after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += yourTube
include $(THEOS_MAKE_PATH)/aggregate.mk
