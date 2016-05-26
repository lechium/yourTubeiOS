//
//  MetadataView.m
//  nitoTV4
//
//  Created by Kevin Bradley on 3/16/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import "MetadataPreviewView.h"
#import "PureLayout.h"
#import "UIView+RecursiveFind.h"
#import "UIImageView+WebCache.h"

@interface UIWindow (AutoLayoutDebug)
+ (UIWindow *)keyWindow;
- (NSString *)_autolayoutTrace;
@end

@implementation MetaDataAsset

@synthesize name, assetDescription, metaDictionary, imagePath, detail, detailOptions;

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    NSMutableDictionary *mutableDict = [dict mutableCopy];
    name = mutableDict[@"name"];
    assetDescription = mutableDict[@"description"];
    imagePath = mutableDict[@"imagePath"];
    detail = mutableDict[@"detail"];
    detailOptions = mutableDict[@"detailOptions"];
    [mutableDict removeObjectForKey:@"name"];
    [mutableDict removeObjectForKey:@"description"];
    [mutableDict removeObjectForKey:@"imagePath"];
    [mutableDict removeObjectForKey:@"detail"];
    [mutableDict removeObjectForKey:@"detailOptions"];
    metaDictionary = mutableDict;
    return self;
}

@end

@implementation MetadataLineView

@synthesize value, label;

- (id)initForAutoLayout
{
    self = [super initForAutoLayout];
    [self addSubview:[self labelLayer]];
    [self addSubview:[self valueLayer]];
    return self;
}

- (id)initWithLabel:(id)theLabel value:(id)theValue minimumLabelWidth:(CGFloat)width
{
    self = [self initForAutoLayout];
    _minLabelWidth = width;
    self.label = [[theLabel capitalizedString] stringByAppendingString:@":"];
    self.value = theValue;
    [self.labelLayer setText:self.label];
    [self.valueLayer setText:theValue];
    return self;
}

- (void)updateConstraints
{
    //CGRectMake(4, 8, 798, 21) label
    //CGRectMake(93, 154, 705, 21)
    [NSLayoutConstraint deactivateConstraints:self.constraints];
    
    //   [self autoCenterInSuperview];
    [self.labelLayer autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:95];
    //[self.labelLayer autoSetDimension:ALDimensionHeight toSize:21];
    [self.labelLayer autoSetDimensionsToSize:CGSizeMake(_minLabelWidth, 21)];
    [self.valueLayer autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.labelLayer withOffset:15];
    //[self autoPinEdgesToSuperviewEdges];
    [self.valueLayer autoSetDimension:ALDimensionHeight toSize:21];
    //[self.valueLayer autoSetDimensionsToSize:CGSizeMake(705, 21)];
    [super updateConstraints];
}

- (UILabel *)labelLayer
{
    if (!_labelLayer)
    {
        _labelLayer = [[UILabel alloc] initForAutoLayout];
        [_labelLayer setFont:[UIFont boldSystemFontOfSize:17]];
        _labelLayer.textAlignment = NSTextAlignmentRight;
        _labelLayer.textColor = [UIColor grayColor];
    }
    return _labelLayer;
}


- (UILabel *)valueLayer
{
    if (!_valueLayer)
    {
        _valueLayer = [[UILabel alloc] initForAutoLayout];
        if (self.backgroundColor == [UIColor blackColor])
        {
            [_valueLayer setTextColor:[UIColor whiteColor]];
        } else {
            [_valueLayer setTextColor:[UIColor blackColor]];
        }
    }
    return _valueLayer;
}


@end

@implementation MetadataLinesView

@synthesize lineArray, values, labels;

- (void)layoutSubviews
{
    [super layoutSubviews];
    //CGFloat startingY = self.superview.frame.origin.y + self.superview.subviews.lastObject.frame.origin.y + 25;
    CGFloat startingY = 10;
    NSInteger currentIndex = 0;
    for (MetadataLineView *lineView in self.subviews)
    {
        CGRect currentFrame = [lineView frame];
        //currentFrame.origin.x = 4;
        currentFrame.origin.y = startingY;
        [lineView setFrame:currentFrame];
        startingY+=21;
        currentIndex++;
        if (currentIndex == self.subviews.count-1)
        {
            startingY+=15;
        }
        
        UIColor *valueColor = [UIColor blackColor];
        
        if (self.superview.superview.superview.backgroundColor == [UIColor blackColor])
        {
            valueColor = [UIColor whiteColor];
            //NSLog(@"is black bg");
        }
        if ([lineView respondsToSelector:@selector(valueLayer)])
        {
            [lineView.valueLayer setTextColor:valueColor];
        }
       
    }
    //[self printRecursiveDescription];
}

- (id)initWithMetadata:(id)theMeta withLabels:(id)theLabels
{
    
    self = [super initForAutoLayout];
    self.values = theMeta;
    self.labels = theLabels;
    [self _layoutLines];
    return self;
}

- (void)_layoutLines
{
    [self removeAllSubviews];
    
    int i = 0;
    NSString *longestLabel = @"";
    for (NSString *label in labels)
    {
        if (label.length > longestLabel.length)
        {
            longestLabel = [[label capitalizedString] stringByAppendingString:@":"];
        }
    }
    UIFont *font = [UIFont boldSystemFontOfSize:17];
    UIColor *color = [UIColor blackColor];
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          color, NSForegroundColorAttributeName,
                                          nil];
    CGSize theSize = [longestLabel sizeWithAttributes:attributesDictionary];
    
    for (NSString *label in labels)
    {
        MetadataLineView *line = [[MetadataLineView alloc] initWithLabel:label value:values[i] minimumLabelWidth:theSize.width + 5];
        [self addSubview:line];
        i++;
    }
    UIView *theView = [[UIView alloc] initWithFrame:CGRectMake(-4, 0, 806, 1)];
    [theView setBackgroundColor:[UIColor darkGrayColor]];
    [self addSubview:theView];
    
}

- (void)setMetadata:(MetaDataAsset *)metadata
{
    NSMutableArray *valueArray = [NSMutableArray new];
    NSMutableArray *keyArray = [NSMutableArray new];
    NSString *currentKey = nil;
    NSEnumerator *keyEnum = [[metadata metaDictionary] keyEnumerator];
    while (currentKey = [keyEnum nextObject])
    {
        [keyArray addObject:currentKey];
        [valueArray addObject:[metadata metaDictionary][currentKey]];
    }
    self.values = valueArray;
    self.labels = keyArray;
    [self _layoutLines];
    // [self updateConstraintsIfNeeded];
}

- (void)setMetadata:(id)metadata withLabels:(id)theLabels frameWidth:(float)width maxHeight:(float)height
{
    self.values = metadata;
    self.labels = theLabels;
    _frameWidth = width;
    _lineHeight = height / values.count;
    [self _layoutLines];
    // [self updateConstraintsIfNeeded];
}
//
//- (void)updateConstraints
//{
//
//    //[NSLayoutConstraint deactivateConstraints:self.constraints];
//    [super updateConstraints];
//
//   /*
//    for (MetadataLineView *lineView in lineArray)
//    {
//        //CGRectMake(4, 8, 798, 21) label
//        //CGRectMake(93, 154, 705, 21)
//    }
//    */
//
//}


@end

//self.metadataView = [[MetadataView alloc] initWithFrame:CGRectMake(100, 809, 806, 265)];

@interface MetadataPreviewView ()

@property (nonatomic, assign) BOOL didSetupConstraints;

@end

@implementation MetadataPreviewView



- (BOOL)hasMeta
{
    if (self.metadataAsset != nil)
    {
        return true;
    }
    return false;
}

- (id)initWithCoverArtNamed:(NSString *)coverArt
{
    self = [self initForAutoLayout];
    self.coverArt = [UIImage imageNamed:coverArt];
    self.imageView.image = self.coverArt;
    return self;
}


- (id)initWithMetadata:(NSDictionary *)meta
{
    self = [self initForAutoLayout];
    // metadataDict = meta;
    self.metadataAsset = [[MetaDataAsset alloc] initWithDictionary:meta];
    NSString *coverArt = meta[@"imagePath"];
    self.coverArt = [UIImage imageNamed:coverArt];
    return self;
}

- (id)initForAutoLayout
{
    
    self = [super initForAutoLayout];
    [self addSubview:self.imageView];
    [self addSubview:self.metaContainerView];
    //[self updateConstraintsIfNeeded];
    return self;
}


- (MetadataLinesView *)linesView
{
    
    if (!_linesView)
    {
        
        _linesView = [[MetadataLinesView alloc] initForAutoLayout];
        
        _linesView.autoresizesSubviews = true;
    }
    return _linesView;
}

- (UIView *)metaContainerView
{
    if (!_metaContainerView)
    {
        _metaContainerView = [UIView newAutoLayoutView];
        [_metaContainerView addSubview:self.topDividerView];
        [_metaContainerView addSubview:self.middleDividerView];
        [_metaContainerView addSubview:self.titleLabel];
        [_metaContainerView addSubview:self.descriptionLabel];
        [_metaContainerView addSubview:self.linesView];
        //[_metaContainerView addSubview:self.bottomDividerView];
        
    }
    return _metaContainerView;
}

- (UIView *)topDividerView
{
    if (!_topDividerView) {
        _topDividerView = [UIView newAutoLayoutView];
        _topDividerView.backgroundColor = [UIColor darkGrayColor];
    }
    return _topDividerView;
}

- (UIView *)bottomDividerView
{
    if (!_bottomDividerView) {
        _bottomDividerView = [UIView newAutoLayoutView];
        _bottomDividerView.backgroundColor = [UIColor redColor];
    }
    return _bottomDividerView;
}


- (UIView *)middleDividerView
{
    if (!_middleDividerView) {
        _middleDividerView = [UIView newAutoLayoutView];
        _middleDividerView.backgroundColor = [UIColor darkGrayColor];
    }
    return _middleDividerView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel newAutoLayoutView];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    return _titleLabel;
}

- (UILabel *)descriptionLabel
{
    if (!_descriptionLabel) {
        _descriptionLabel = [UILabel newAutoLayoutView];
        _descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _descriptionLabel.numberOfLines = 0;
    }
    return _descriptionLabel;
}


- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [UIImageView newAutoLayoutView];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.image = [UIImage imageNamed:@"package"];
    }
    return _imageView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
    //NSLog(@"%@", recursiveDesc);
    
    //NSString *autolayoutTrace = [[UIWindow keyWindow] _autolayoutTrace];
    //NSLog(@"alt: %@", autolayoutTrace);
}



- (void)updateConstraints
{
    //[NSLayoutConstraint deactivateConstraints:self.constraints];
    
    // if (!self.didSetupConstraints)
    //{
    //NSLog(@"superview frame: %@", NSStringFromCGRect(self.superview.frame));
    //[self autoCenterInSuperview];
    //[self autoPinEdgesToSuperviewEdges];
    [self.imageView autoSetDimensionsToSize:CGSizeMake(512, 512)];
    
    self.centeredImageConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
        
        [self.imageView autoCenterInSuperview];
    }];
    
    self.hasMetaConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
        
        [self.imageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.imageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.superview withOffset:264];
    }];
    
    if (!self.hasMeta)
    {
        [self.centeredImageConstraints autoInstallConstraints];
        
    } else {
        
        [self.hasMetaConstraints autoInstallConstraints];
        [self.metaContainerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imageView withOffset:10];
        [self.metaContainerView autoSetDimensionsToSize:CGSizeMake(806, 265)];
        [self.metaContainerView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        // [self.metaContainerView setBackgroundColor:[UIColor redColor]];
        //UIView *lineViewGuide = nil;
        
        [self.titleLabel autoSetDimensionsToSize:CGSizeMake(504, 21)];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:4];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:8];
        
        //self.titleLabel.text = self.metadataDict[@"Name"];
        self.titleLabel.text = self.metadataAsset.name;
        
        [self.topDividerView autoSetDimensionsToSize:CGSizeMake(806, 1)];
        [self.topDividerView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.topDividerView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.topDividerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:8];
        
        self.noDescriptionConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
            
            [self.linesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topDividerView withOffset:5];
        }];
        
        self.descriptionConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
           
            [self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:4];
            [self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.topDividerView withOffset:15];
            [self.descriptionLabel autoSetDimension:ALDimensionWidth toSize:798];
            self.descriptionLabel.text = self.metadataAsset.assetDescription;
            
            [self.middleDividerView autoSetDimensionsToSize:CGSizeMake(806, 1)];
            [self.middleDividerView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [self.middleDividerView autoPinEdgeToSuperviewEdge:ALEdgeRight];
            [self.middleDividerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.descriptionLabel withOffset:15];
            
            [self.linesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.middleDividerView withOffset:5];
            
            
            
        }];
        
        if ([self.metadataAsset.assetDescription length] > 0)
        {
            //[self.noDescriptionConstraints autoRemoveConstraints];
            [self.descriptionConstraints autoInstallConstraints];
            
        } else {
        
            [self.noDescriptionConstraints autoInstallConstraints];
            
        }
        
        //[self.linesView setClipsToBounds:true];
        //[self.linesView autoSetDimension:ALDimensionHeight toSize:150];
        //[self.linesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:lineViewGuide withOffset:5];
        [self.linesView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:4];
        [self.linesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        [self.linesView setMetadata:self.metadataAsset];
        //[self.linesView setMetadata:self.metadataDict[@"Values"] withLabels:self.metadataDict[@"Labels"] frameWidth:0 maxHeight:0];
        /*
         [self.bottomDividerView autoSetDimensionsToSize:CGSizeMake(806, 1)];
        [self.bottomDividerView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.bottomDividerView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [self.bottomDividerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.linesView withOffset:20];
        */
        
        
        
        
        
        
        // NSArray *subviews = self.linesView.subviews;
        /*
         int i = 0;
         MetadataLineView *previousView = nil;
         for (MetadataLineView *lineView in self.linesView.subviews)
         {
         if (i == 0)
         {
         //[lineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.middleDividerView withOffset:5];
         [lineView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:5];
         } else {
         previousView = self.linesView.subviews[i-1];
         NSLog(@"previousView: %@", previousView);
         [lineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:21];
         }
         i++;
         }
         */
     //   [self.linesView.subviews autoDistributeViewsAlongAxis:ALAxisVertical alignedTo:ALAttributeVertical withFixedSpacing:21 insetSpacing:NO matchedSizes:NO];
        [self.linesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        // [self.linesView.subviews autoDistributeViewsAlongAxis:ALAxisVertical alignedTo:ALAttributeVertical withFixedSpacing:10 insetSpacing:false];
        ;
        
        
        
    }
    //   self.didSetupConstraints = true;
    
    // }
    //   [NSLayoutConstraint deactivateConstraints:self.constraints];
    [super updateConstraints];
}

- (void)updateAsset:(MetaDataAsset *)asset
{
    
    self.metadataAsset = asset;
    self.titleLabel.text = asset.name;
    self.descriptionLabel.text = asset.assetDescription;
    [self.linesView setMetadata:asset];
    
    if ([[[asset metaDictionary] allKeys] count] == 0)
    {
        self.linesView.alpha = 0;
    } else {
        self.linesView.alpha = 1;
    }
    
    if (asset.assetDescription.length == 0 && ([[[asset metaDictionary] allKeys] count] == 0))
    {
        self.topDividerView.alpha = 0;
    } else {
        self.topDividerView.alpha = 1;
    }
    
    //[self.linesView setMetadata:self.metadataDict[@"Values"] withLabels:self.metadataDict[@"Labels"] frameWidth:0 maxHeight:0];
    if ([asset.assetDescription length] > 0)
    {
        [self.noDescriptionConstraints autoRemoveConstraints];
        [self.descriptionConstraints autoInstallConstraints];
    } else {
        [self.descriptionConstraints autoRemoveConstraints];
        [self.noDescriptionConstraints autoInstallConstraints];
    }
    //[self updateConstraintsIfNeeded];
    //[self updateConstraints];
   // [self layoutIfNeeded];
}




/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
