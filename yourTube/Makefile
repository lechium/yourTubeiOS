include theos/makefiles/common.mk

TARGET = iphone:8.4
export GO_EASY_ON_ME=1
export SDKVERSION=8.4
export ARCHS = armv7

APPLICATION_NAME = yourTube
yourTube_FILES = main.m yourTubeApplication.m OurViewController.mm KBYourTube.m KBYTDownloadStream.m Download/URLCredential.m Download/URLDownloader.m
yourTube_FILES += APDeviceController.m KBYTPreferences.m
yourTube_FRAMEWORKS = UIKit CoreGraphics WebKit AVFoundation AVKit AppSupport AudioToolbox
yourTube_CXXFLAGS += -fobjc-arc
yourTube_CFLAGS += -fobjc-arc
yourTube_LDFLAGS = -ObjC -undefined dynamic_lookup -F/Applications/Xcode7.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.4.sdk/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "su -c uicache mobile"
	install.exec "apt-get install -f -y --force-yes"
