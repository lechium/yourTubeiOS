//
//  CollectionViewLayout.h
//  CollectionViewSample
//
//  Created by DilumNavanjana on 6/4/14.
//  Copyright (c) 2014 DilumNavanjana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewLayout : UICollectionViewFlowLayout
{
    UICollectionViewScrollDirection scrollDirection;
}
@property (nonatomic) UICollectionViewScrollDirection scrollDirection;

-(UICollectionViewScrollDirection) scrollDirection;
@end
