// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewConfiguration.h"

#import <LTKit/UIDevice+Hardware.h>

#import "PTUCellSizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUCollectionViewConfiguration

- (instancetype)initWithAssetCellSizingStrategy:(id<PTUCellSizingStrategy>)assetSizingStrategy
                        albumCellSizingStrategy:(id<PTUCellSizingStrategy>)albumSizingStrategy
                       headerCellSizingStrategy:(id<PTUCellSizingStrategy>)headerCellSizingStrategy
                             minimumItemSpacing:(CGFloat)minimumItemSpacing
                             minimumLineSpacing:(CGFloat)minimumLineSpacing
                                scrollDirection:(UICollectionViewScrollDirection)scrollDirection
                    showVerticalScrollIndicator:(BOOL)showVerticalScrollIndicator
                  showHorizontalScrollIndicator:(BOOL)showHorizontalScrollIndicator
                                   enablePaging:(BOOL)enablePaging {
  if (self = [super init]) {
    _assetCellSizingStrategy = assetSizingStrategy;
    _albumCellSizingStrategy = albumSizingStrategy;
    _headerCellSizingStrategy = headerCellSizingStrategy;
    _minimumItemSpacing = minimumItemSpacing;
    _minimumLineSpacing = minimumLineSpacing;
    _scrollDirection = scrollDirection;
    _showsVerticalScrollIndicator = showVerticalScrollIndicator;
    _showsHorizontalScrollIndicator = showHorizontalScrollIndicator;
    _enablePaging = enablePaging;
  }
  return self;
}

+ (instancetype)defaultConfiguration {
  id<PTUCellSizingStrategy> assetSizingStrategy =
      [PTUCellSizingStrategy adaptiveFitRow:CGSizeMake(92, 92) maximumScale:1.2
                        preserveAspectRatio:YES];
  id<PTUCellSizingStrategy> albumSizingStrategy = [PTUCellSizingStrategy rowWithHeight:100];
  id<PTUCellSizingStrategy> headerSizingStrategy = [PTUCellSizingStrategy rowWithHeight:25];
  return [[PTUCollectionViewConfiguration alloc] initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy headerCellSizingStrategy:headerSizingStrategy
      minimumItemSpacing:1 minimumLineSpacing:1
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:NO];
}

+ (instancetype)photoStrip {
  id<PTUCellSizingStrategy> assetSizingStrategy = [PTUCellSizingStrategy gridWithItemsPerColumn:1];
  id<PTUCellSizingStrategy> albumSizingStrategy = [PTUCellSizingStrategy gridWithItemsPerColumn:1];
  id<PTUCellSizingStrategy> headerSizingStrategy = [PTUCellSizingStrategy constant:CGSizeZero];
  return [[PTUCollectionViewConfiguration alloc] initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy headerCellSizingStrategy:headerSizingStrategy
      minimumItemSpacing:0 minimumLineSpacing:1
      scrollDirection:UICollectionViewScrollDirectionHorizontal showVerticalScrollIndicator:NO
      showHorizontalScrollIndicator:NO enablePaging:NO];
}

+ (instancetype)defaultIPadConfiguration {
  id<PTUCellSizingStrategy> assetSizingStrategy =
      [PTUCellSizingStrategy adaptiveFitRow:CGSizeMake(140, 140) maximumScale:1.6
                        preserveAspectRatio:YES];
  id<PTUCellSizingStrategy> albumSizingStrategy =
      [PTUCellSizingStrategy adaptiveFitRow:CGSizeMake(683, 150) maximumScale:0.3
                        preserveAspectRatio:NO];
  id<PTUCellSizingStrategy> headerSizingStrategy = [PTUCellSizingStrategy rowWithHeight:25];
  return [[PTUCollectionViewConfiguration alloc] initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy headerCellSizingStrategy:headerSizingStrategy
      minimumItemSpacing:1 minimumLineSpacing:1
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:NO];
}

+ (instancetype)deviceAdjustableConfiguration {
  return [[UIDevice currentDevice] lt_isPadIdiom] ?
      [self defaultIPadConfiguration] : [self defaultConfiguration];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, asset cell sizing strategy: %@, album cell sizing "
          "strategy %@, header cell sizing strategy: %@, minimum item spacing: %g, minimum line "
          "spacing: %g, scroll direction: %lu, shows vertical scroll indicator: %lu, shows "
          "horizontal scroll indicator: %lu, enable paging: %lu>", self.class, self,
          self.assetCellSizingStrategy, self.albumCellSizingStrategy, self.headerCellSizingStrategy,
          self.minimumLineSpacing, self.minimumLineSpacing, (unsigned long)self.scrollDirection,
          (unsigned long)self.showsVerticalScrollIndicator,
          (unsigned long)self.showsHorizontalScrollIndicator, (unsigned long)self.enablePaging];
}

- (BOOL)isEqual:(PTUCollectionViewConfiguration *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return (self.assetCellSizingStrategy == object.assetCellSizingStrategy ||
      [self.assetCellSizingStrategy isEqual:object.assetCellSizingStrategy]) &&
      (self.albumCellSizingStrategy == object.albumCellSizingStrategy ||
      [self.albumCellSizingStrategy isEqual:object.albumCellSizingStrategy]) &&
      (self.headerCellSizingStrategy == object.headerCellSizingStrategy ||
      [self.headerCellSizingStrategy isEqual:object.headerCellSizingStrategy]) &&
      self.minimumItemSpacing == object.minimumItemSpacing &&
      self.minimumLineSpacing == object.minimumLineSpacing &&
      self.scrollDirection == object.scrollDirection &&
      self.showsVerticalScrollIndicator == object.showsVerticalScrollIndicator &&
      self.showsHorizontalScrollIndicator == object.showsHorizontalScrollIndicator &&
      self.enablePaging == object.enablePaging;
}

- (NSUInteger)hash {
  return self.assetCellSizingStrategy.hash ^ self.albumCellSizingStrategy.hash ^
      self.headerCellSizingStrategy.hash ^ @(self.minimumItemSpacing).hash ^
      @(self.minimumLineSpacing).hash ^ @(self.scrollDirection).hash ^
      @(self.showsVerticalScrollIndicator).hash ^ @(self.showsHorizontalScrollIndicator).hash ^
      @(self.enablePaging).hash;
}

@end

NS_ASSUME_NONNULL_END
