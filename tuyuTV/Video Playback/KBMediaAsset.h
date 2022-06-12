//
//  KBMediaAsset.h
//  Ethereal
//
//  Created by kevinbradley on 9/17/21.
//  Copyright © 2021 nito. All rights reserved.
//

#import "MetadataPreviewView.h"

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, KBMediaAssetType) {
    KBMediaAssetTypeDirectory, //Directory
    KBMediaAssetTypeVideoDefault, //Whether or not its apple compatible format, H264, MPEG4 etc...
    KBMediaAssetTypeVideoCustom, //Whether or not its a custom format that needs the external framework to play.
};


@interface KBMediaAsset : MetaDataAsset
@property KBMediaAssetType assetType;
@property NSString *filePath;
@end

NS_ASSUME_NONNULL_END
