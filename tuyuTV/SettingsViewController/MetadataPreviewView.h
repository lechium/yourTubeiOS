//
//  MetadataView.h
//  nitoTV4
//
//  Created by Kevin Bradley on 3/16/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 
 MetaDataAsset is the fundamental base class for all information on what is displayed for each item in the table view and its associated MetadataPreviewView.
 
 the formatting is as follows
 
 [coverArt] //can be remove or local
 
 [name]
 -------------------------------------

 [assetDescription]
 
 -------------------------------------
  
  [metaDictionary.key[x]]: metadataDictionary.value[x]]
 ..
 
 -------------------------------------
 
 
 */

@interface MetaDataAsset: NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *assetDescription;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *imagePathDark; //optional
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, strong) NSArray *detailOptions;
@property (nonatomic, strong) NSDictionary *metaDictionary;
@property (nonatomic, strong) NSString *selectorName;
@property (readwrite, assign) NSInteger tag;
@property (nonatomic, strong) NSString *fullImagePath; //optional
@property (nonatomic, strong) NSString *defaultImageName; //optional
@property (readwrite, assign) BOOL accessory;

- (SEL)ourSelector;

- (id)initWithDictionary:(NSDictionary *)dict;

@end

@interface MetadataLinesView: UIView
{
    float _lineHeight;	// 92 = 0x5c
    float _frameWidth;
}

@property (nonatomic, strong) NSArray *lineArray;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSArray *labels;

- (id)initWithMetadata:(id)theMeta withLabels:(id)theLabels;
- (void)_layoutLines;
- (void)setMetadata:(id)metadata withLabels:(id)theLabels frameWidth:(float)width maxHeight:(float)height;
- (void)setMetadata:(MetaDataAsset *)metadata;
@end

@interface MetadataLineView: UIView
{
    float _maxLabelWidth;	// 92 = 0x5c
    CGFloat _minLabelWidth;	// 92 = 0x5c
}

@property (nonatomic, strong) NSString *value;
@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) UILabel *labelLayer;
@property (nonatomic, strong) UILabel *valueLayer;

- (id)initWithLabel:(id)theLabel value:(id)theValue minimumLabelWidth:(CGFloat)width;

@end

@interface MetadataPreviewView : UIView

@property (nonatomic, strong) UIImage *coverArt;

#define DEFAULT_TOP_OFFSET 264

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *metaContainerView;

@property (nonatomic, strong) UIView *topDividerView;
@property (nonatomic, strong) UIView *middleDividerView;
@property (nonatomic, strong) UIView *bottomDividerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) MetadataLinesView *linesView;
@property (readwrite, assign) CGFloat topOffset;
//image view constraints for when there is no meta visible
@property (nonatomic, strong) NSArray *centeredImageConstraints;

//image view constraints for when there is meta visible
@property (nonatomic, strong) NSArray *hasMetaConstraints;

//the layout constraints are when there is a description
@property (nonatomic, strong) NSArray *descriptionConstraints;

//layout constraints without description present in the asset
@property (nonatomic, strong) NSArray *noDescriptionConstraints;

//the asset that populates the metadata
@property (nonatomic, strong) MetaDataAsset *metadataAsset;

- (id)initWithCoverArtNamed:(NSString *)coverArt;
- (id)initWithMetadata:(NSDictionary *)meta;
- (BOOL)hasMeta;
- (void)updateAsset:(MetaDataAsset *)asset;

@end
