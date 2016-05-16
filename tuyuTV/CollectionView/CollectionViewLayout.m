//
//  CollectionViewLayout.m
//  CollectionViewSample
//
//  Created by DilumNavanjana on 6/4/14.
//  Copyright (c) 2014 DilumNavanjana. All rights reserved.
//

#import "CollectionViewLayout.h"

@implementation CollectionViewLayout

-(id)init
{
    //NSLog(@"init");
    self = [super init];
    if (self) {
        self.itemSize = CGSizeMake(320, 420);
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.sectionInset = UIEdgeInsetsMake(35, 0, 20.0, 0.0);
        self.minimumInteritemSpacing = 10;
        self.minimumLineSpacing = 50;
    }
    return self;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds
{
    return YES;
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray* array = [super layoutAttributesForElementsInRect:rect];
   // CGRect visibleRect;
    //visibleRect.origin = self.collectionView.contentOffset;
    //visibleRect.size = self.collectionView.bounds.size;
    
    return array;
}

/*

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat offsetAdjustment = MAXFLOAT;
    //NSLog(@"oa: %f", offsetAdjustment);
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0);
   // NSLog(@"horizontalCenter: %f", horizontalCenter);
    
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
   
    //NSLog(@"targetRect: %@", NSStringFromCGRect(targetRect));
    
    NSArray* array = [super layoutAttributesForElementsInRect:targetRect];
    
    for (UICollectionViewLayoutAttributes* layoutAttributes in array) {
        CGFloat itemHorizontalCenter = layoutAttributes.center.x;
      //  NSLog(@"itemHorizontalCenter: %f", itemHorizontalCenter);
        
        if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment)) {
       
            CGFloat firstSide = ABS(itemHorizontalCenter - horizontalCenter);
            CGFloat secondSide = ABS(offsetAdjustment);
            
           // NSLog(@"%f < %f", firstSide, secondSide);
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
           // NSLog(@"%f", offsetAdjustment);
            
        }
    }
    return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
}

*/
@end
