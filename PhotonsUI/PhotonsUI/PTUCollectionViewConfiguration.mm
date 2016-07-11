// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCollectionViewConfiguration.h"

#import "PTUCellSizingStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUCollectionViewConfiguration

- (instancetype)initWithAssetCellSizingStrategy:(id<PTUCellSizingStrategy>)assetSizingStrategy
                        albumCellSizingStrategy:(id<PTUCellSizingStrategy>)albumSizingStrategy
                             minimumItemSpacing:(CGFloat)minimumItemSpacing
                             minimumLineSpacing:(CGFloat)minimumLineSpacing
                                scrollDirection:(UICollectionViewScrollDirection)scrollDirection
                    showVerticalScrollIndicator:(BOOL)showVerticalScrollIndicator
                  showHorizontalScrollIndicator:(BOOL)showHorizontalScrollIndicator
                                   enablePaging:(BOOL)enablePaging {
  if (self = [super init]) {
    _assetCellSizingStrategy = assetSizingStrategy;
    _albumCellSizingStrategy = albumSizingStrategy;
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
      [PTUCellSizingStrategy adaptiveFitRow:CGSizeMake(100, 100) maximumScale:1.2];
  id<PTUCellSizingStrategy> albumSizingStrategy = [PTUCellSizingStrategy rowWithHeight:100];
  return [[PTUCollectionViewConfiguration alloc] initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy minimumItemSpacing:1 minimumLineSpacing:1
      scrollDirection:UICollectionViewScrollDirectionVertical showVerticalScrollIndicator:YES
      showHorizontalScrollIndicator:NO enablePaging:NO];
}

+ (instancetype)photoStrip {
  id<PTUCellSizingStrategy> assetSizingStrategy = [PTUCellSizingStrategy gridWithItemsPerColumn:1];
  id<PTUCellSizingStrategy> albumSizingStrategy = [PTUCellSizingStrategy gridWithItemsPerColumn:1];
  return [[PTUCollectionViewConfiguration alloc] initWithAssetCellSizingStrategy:assetSizingStrategy
      albumCellSizingStrategy:albumSizingStrategy minimumItemSpacing:1 minimumLineSpacing:0
      scrollDirection:UICollectionViewScrollDirectionHorizontal showVerticalScrollIndicator:NO
      showHorizontalScrollIndicator:NO enablePaging:NO];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, asset cell sizing strategy: %@, album cell sizing "
          "strategy %@, minimum item spacing: %g, minimum line spacing: %g, scroll direction: %lu, "
          "shows vertical scroll indicator: %lu, shows horizontal scroll indicator: %lu, enable "
          "paging: %lu>", self.class, self, self.assetCellSizingStrategy,
          self.albumCellSizingStrategy, self.minimumLineSpacing, self.minimumLineSpacing,
          (unsigned long)self.scrollDirection, (unsigned long)self.showsVerticalScrollIndicator,
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
      self.minimumItemSpacing == object.minimumItemSpacing &&
      self.minimumLineSpacing == object.minimumLineSpacing &&
      self.scrollDirection == object.scrollDirection &&
      self.showsVerticalScrollIndicator == object.showsVerticalScrollIndicator &&
      self.showsHorizontalScrollIndicator == object.showsHorizontalScrollIndicator &&
      self.enablePaging == object.enablePaging;
}

- (NSUInteger)hash {
  return self.assetCellSizingStrategy.hash ^ self.albumCellSizingStrategy.hash ^
      @(self.minimumItemSpacing).hash ^ @(self.minimumLineSpacing).hash ^
      @(self.scrollDirection).hash ^ @(self.showsVerticalScrollIndicator).hash ^
      @(self.showsHorizontalScrollIndicator).hash ^ @(self.enablePaging).hash;
}

@end

NS_ASSUME_NONNULL_END
