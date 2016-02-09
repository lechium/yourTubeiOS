include theos/makefiles/common.mk
ARCHS = armv7 armv7s arm64
TARGET = iphone:8.4
export GO_EASY_ON_ME=1
export SDKVERSION=8.4
export ARCHS = armv7 armv7s arm64

APPLICATION_NAME = yourTube
yourTube_FILES = main.m yourTubeApplication.m OurViewController.mm KBYourTube.m KBYTDownloadStream.m Download/URLCredential.m Download/URLDownloader.m KBYTDownloadsTableViewController.m
yourTube_FILES += APDeviceController.m KBYTPreferences.m UIColor+Additions.m UIImage+Scale.m MarqueeLabel/MarqueeLabel.m KBYTSearchTableViewController.m KBYTSearchItemViewController.m
yourTube_FILES += SDWebImage/MKAnnotationView+WebCache.m
yourTube_FILES += SDWebImage/NSData+ImageContentType.m
yourTube_FILES += SDWebImage/SDImageCache.m
yourTube_FILES += SDWebImage/SDWebImageCompat.m
yourTube_FILES += SDWebImage/SDWebImageDecoder.m
yourTube_FILES += SDWebImage/SDWebImageDownloader.m
yourTube_FILES += SDWebImage/SDWebImageDownloaderOperation.m
yourTube_FILES += SDWebImage/SDWebImageManager.m
yourTube_FILES += SDWebImage/SDWebImagePrefetcher.m
yourTube_FILES += SDWebImage/UIButton+WebCache.m
yourTube_FILES += SDWebImage/UIImage+GIF.m
yourTube_FILES += SDWebImage/UIImage+MultiFormat.m
yourTube_FILES += SDWebImage/UIImage+WebP.m
yourTube_FILES += SDWebImage/UIImageView+HighlightedWebCache.m
yourTube_FILES += SDWebImage/UIImageView+WebCache.m
yourTube_FILES += SDWebImage/UIView+WebCacheOperation.m
yourTube_FILES += APDocument/APAttribute.m APDocument/APDocument.m APDocument/APElement.m
yourTube_FILES += SVProgressHUD/SVIndefiniteAnimatedView.m SVProgressHUD/SVProgressHUD.m SVProgressHUD/SVRadialGradientLayer.m
yourTube_FILES += Animations/BaseAnimation.m Animations/ModalAnimation.m Animations/ScaleAnimation.m Animations/ShuffleAnimation.m Animations/SlideAnimation.m
yourTube_FILES += KBYourTube+Categories.m KBYTMessagingCenter.m JGProgressView/JGProgressView.m

yourTube_FRAMEWORKS = UIKit CoreGraphics WebKit AVFoundation AVKit AppSupport AudioToolbox MapKit
yourTube_CXXFLAGS += -fobjc-arc
yourTube_CFLAGS += -fobjc-arc
yourTube_LDFLAGS = -ObjC -undefined dynamic_lookup -F/Applications/Xcode7.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.4.sdk/System/Library/PrivateFrameworks -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "su -c uicache mobile"
	install.exec "apt-get install -f -y --force-yes"


