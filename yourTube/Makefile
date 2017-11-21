ARCHS = armv7 armv7s arm64
TARGET = iphone:9.3
export GO_EASY_ON_ME=1
include theos/makefiles/common.mk
export SDKVERSION=9.3
export DEBUG=1
export ARCHS = armv7 armv7s arm64


APPLICATION_NAME = yourTube
yourTube_FILES = main.m yourTubeApplication.m KBYourTube.m KBYTDownloadStream.m Download/URLCredential.m Download/URLDownloader.m KBYTDownloadsTableViewController.m KBYTDownloadCell.m KBYTWebViewController.mm
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
yourTube_FILES += Reachability/Reachability.m Ono/ONOXMLDocument.m RNFrostedSidebar/RNFrostedSidebar.m
yourTube_FILES += KBYTGenericVideoTableViewController.m YTKBPlayerViewController.m KBYTQueuePlayer.m
yourTube_FILES += KBYTDownloadManager.m KBYTDownloadOperation.m
yourTube_FILES += ../tuyuTV/TYAuthUserManager.m
yourTube_FILES += AFNetworking/AFgzipRequestSerializer.m AFNetworking/AFHTTPSessionManager.m AFNetworking/AFNetworkReachabilityManager.m
yourTube_FILES += AFNetworking/AFSecurityPolicy.m AFNetworking/AFURLRequestSerialization.m AFNetworking/AFURLResponseSerialization.m AFNetworking/AFURLSessionManager.m
yourTube_FILES += AFOAuth2Manager/AFHTTPRequestSerializer+OAuth2.m AFOAuth2Manager/AFOAuth2Manager.m AFOAuth2Manager/AFOAuthCredential.m


yourTube_FRAMEWORKS = UIKit CoreGraphics WebKit AVFoundation AVKit AppSupport AudioToolbox MapKit QuartzCore Accelerate
yourTube_CXXFLAGS += -fobjc-arc -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/libxml2
yourTube_CFLAGS += -fobjc-arc -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/libxml2
yourTube_LDFLAGS = -ObjC -undefined dynamic_lookup -I/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.4.sdk/usr/include/libxml2 -lxml2 -F/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/PrivateFrameworks -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "su -c uicache mobile"
	install.exec "apt-get install -f -y --force-yes"


