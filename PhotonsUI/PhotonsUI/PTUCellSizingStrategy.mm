// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCellSizingStrategy.h"

#import <LTKit/LTCGExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTUCellSizingStrategy

+ (id<PTUCellSizingStrategy>)constant:(CGSize)size {
  return [[PTUConstantCellSizingStrategy alloc] initWithSize:size];
}

+ (id<PTUCellSizingStrategy>)adaptiveFitRow:(CGSize)size maximumScale:(CGFloat)maximumScale
                        preserveAspectRatio:(BOOL)preserveAspectRatio {
  return [[PTUAdaptiveCellSizingStrategy alloc] initWithSize:size maximumScale:maximumScale
                                                  matchWidth:YES
                                         preserveAspectRatio:preserveAspectRatio];
}

+ (id<PTUCellSizingStrategy>)adaptiveFitColumn:(CGSize)size maximumScale:(CGFloat)maximumScale
                           preserveAspectRatio:(BOOL)preserveAspectRatio {
  return [[PTUAdaptiveCellSizingStrategy alloc] initWithSize:size maximumScale:maximumScale
                                                  matchWidth:NO
                                         preserveAspectRatio:preserveAspectRatio];
}

+ (id<PTUCellSizingStrategy>)rowWithHeight:(CGFloat)height {
  return [[PTURowSizingStrategy alloc] initWithHeight:height];
}

+ (id<PTUCellSizingStrategy>)rowWithWidthRatio:(CGFloat)ratio {
  return [[PTUDynamicRowSizingStrategy alloc] initWithWidthRatio:ratio];
}

+ (id<PTUCellSizingStrategy>)gridWithItemsPerRow:(NSUInteger)itemsPerRow {
  return [[PTUGridSizingStrategy alloc] initWithItemsPerRow:itemsPerRow];
}

+ (id<PTUCellSizingStrategy>)gridWithItemsPerColumn:(NSUInteger)itemsPerColumn {
  return [[PTUGridSizingStrategy alloc] initWithItemsPerColumn:itemsPerColumn];
}

@end

#pragma mark -
#pragma mark PTUConstantCellSizingStrategy
#pragma mark -

@interface PTUConstantCellSizingStrategy ()

/// Size defining the cell size returned by this strategy.
@property (readonly, nonatomic) CGSize size;

@end

@implementation PTUConstantCellSizingStrategy

- (instancetype)initWithSize:(CGSize)size {
  LTParameterAssert(size.width >= 0 && size.height >= 0, @"Size must equal to or greater than "
                    "zero, got: %@", NSStringFromCGSize(size));
  if (self = [super init]) {
    _size = size;
  }
  return self;
}

- (CGSize)cellSizeForViewSize:(CGSize __unused)viewSize itemSpacing:(CGFloat __unused)itemSpacing
                  lineSpacing:(CGFloat __unused)lineSpacing {
  return self.size;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, size: %@>", self.class, self,
          NSStringFromCGSize(self.size)];
}

- (BOOL)isEqual:(PTUConstantCellSizingStrategy *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return CGSizeEqualToSize(self.size, object.size);
}

- (NSUInteger)hash {
  return @(self.size.height).hash ^ @(self.size.width).hash;
}

@end

#pragma mark -
#pragma mark PTUAdaptiveCellSizingStrategy
#pragma mark -

@interface PTUAdaptiveCellSizingStrategy ()

/// Size defining the cell size returned by this strategy.
@property (readonly, nonatomic) CGSize size;

/// Allowed scaling in order to fit cells perfectly in with or height of the view.
@property (readonly, nonatomic) CGFloat maximumScale;

/// \c YES if \c items should fit perfectly in each row or \c NO if items should fit perfectly in
/// each column.
@property (readonly, nonatomic) BOOL matchWidth;

/// \c YES to apply any scaling to both dimensions instead of just the fitted one.
@property (readonly, nonatomic) BOOL preserveAspectRatio;

@end

@implementation PTUAdaptiveCellSizingStrategy

- (instancetype)initWithSize:(CGSize)size maximumScale:(CGFloat)maximumScale
                  matchWidth:(BOOL)matchWidth preserveAspectRatio:(BOOL)preserveAspectRatio {
  LTParameterAssert(size.width > 0 && size.height > 0, @"Size must be positive, got: %@",
                    NSStringFromCGSize(size));
  LTParameterAssert(maximumScale > 0, @"Maximum scale must be greater than 0, got: %g",
                    maximumScale);
  if (self = [super init]) {
    _size = size;
    _maximumScale = maximumScale;
    _matchWidth = matchWidth;
    _preserveAspectRatio = preserveAspectRatio;
  }
  return self;
}

- (CGSize)cellSizeForViewSize:(CGSize)viewSize itemSpacing:(CGFloat)itemSpacing
                  lineSpacing:(CGFloat)lineSpacing {
  CGFloat sizeToMatch = self.matchWidth ? viewSize.width : viewSize.height;
  CGFloat spacing = self.matchWidth ? itemSpacing : lineSpacing;
  CGFloat itemSize = self.matchWidth ? self.size.width : self.size.height;

  // Finds x such that (itemSize * x) + (itemSpacing * (x - 1)) = viewSize.
  // x is the number of items that will exactly fill the view with the given spacing between each
  // item. Let y = floor(x) (or y = ceil(x) if max scaling is less than 1) be the closest natural
  // number of items to the number that fills the view. find z such that
  // (itemSize * z * y) + (itemSpacing * (y - 1)) = viewSize. z is the minimum scaling required to
  // apply on itemSize for them to perfectly fit within viewSize with itemSpacing between them.
  float fracturedFittingItems = (sizeToMatch + spacing) / (itemSize + spacing);
  int fittingItems;
  if (self.maximumScale >= 1) {
    fittingItems = std::floor(fracturedFittingItems);
  } else {
    fittingItems = std::ceil(fracturedFittingItems);
  }
  if (fittingItems <= 0) {
    return self.size;
  }

  CGFloat itemFittingSize = (sizeToMatch - (spacing * (fittingItems - 1))) / fittingItems;
  if ((self.maximumScale >= 1 && itemFittingSize > itemSize * self.maximumScale) ||
      (self.maximumScale < 1 && itemFittingSize < itemSize * self.maximumScale)) {
    return self.size;
  }

  CGFloat scale = self.preserveAspectRatio ? (itemFittingSize / itemSize) : 1;
  return self.matchWidth ?
      CGSizeMake(itemFittingSize, self.size.height * scale) :
      CGSizeMake(self.size.width * scale, itemFittingSize);
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, size: %@, maximum scale: %g, match width: %lu, "
          "preserve aspect ratio: %lu>", self.class, self, NSStringFromCGSize(self.size),
          self.maximumScale, (unsigned long)self.matchWidth,
          (unsigned long)self.preserveAspectRatio];
}

- (BOOL)isEqual:(PTUAdaptiveCellSizingStrategy *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return CGSizeEqualToSize(self.size, object.size) && self.maximumScale == object.maximumScale &&
      self.matchWidth == object.matchWidth &&
      self.preserveAspectRatio == object.preserveAspectRatio;
}

- (NSUInteger)hash {
  return @(self.size.height).hash ^ @(self.size.width).hash ^ @(self.maximumScale).hash ^
      @(self.matchWidth).hash ^ @(self.preserveAspectRatio).hash;
}

@end

#pragma mark -
#pragma mark PTURowSizingStrategy
#pragma mark -

@interface PTURowSizingStrategy ()

/// Height of rows returned by this sizing strategy.
@property (readonly, nonatomic) CGFloat height;

@end

@implementation PTURowSizingStrategy

- (instancetype)initWithHeight:(CGFloat)height {
  LTParameterAssert(height > 0, @"Height must be positive, got: %g", height);
  if (self = [super init]) {
    _height = height;
  }
  return self;
}

- (CGSize)cellSizeForViewSize:(CGSize)viewSize itemSpacing:(CGFloat __unused)itemSpacing
                  lineSpacing:(CGFloat __unused)lineSpacing {
  return CGSizeMake(viewSize.width, self.height);
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, height: %g>", self.class, self, self.height];
}

- (BOOL)isEqual:(PTURowSizingStrategy *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return self.height == object.height;
}

- (NSUInteger)hash {
  return @(self.height).hash;
}

@end

#pragma mark -
#pragma mark PTUDynamicRowSizingStrategy
#pragma mark -

@interface PTUDynamicRowSizingStrategy ()

/// Width to height ratio of rows returned by this strategy.
@property (readonly, nonatomic) CGFloat ratio;

@end

@implementation PTUDynamicRowSizingStrategy

- (instancetype)initWithWidthRatio:(CGFloat)ratio {
  LTParameterAssert(ratio > 0, @"Ratio must be positive, got: %g", ratio);
  if (self = [super init]) {
    _ratio = ratio;
  }
  return self;
}

- (CGSize)cellSizeForViewSize:(CGSize)viewSize itemSpacing:(CGFloat __unused)itemSpacing
                  lineSpacing:(CGFloat __unused)lineSpacing {
  return CGSizeMake(viewSize.width, viewSize.width * self.ratio);
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, ratio: %g>", self.class, self, self.ratio];
}

- (BOOL)isEqual:(PTUDynamicRowSizingStrategy *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return self.ratio == object.ratio;
}

- (NSUInteger)hash {
  return @(self.ratio).hash;
}

@end

#pragma mark -
#pragma mark PTUGridSizingStrategy
#pragma mark -

@interface PTUGridSizingStrategy ()

/// Items per row determined by this sizing strategy.
@property (readonly, nonatomic) NSUInteger items;

/// \c YES if \c items should fit perfectly in each row or \c NO if items should fit perfectly in
/// each column.
@property (readonly, nonatomic) BOOL matchRow;

@end

@implementation PTUGridSizingStrategy

- (instancetype)initWithItemsPerRow:(NSUInteger)itemsPerRow {
  LTParameterAssert(itemsPerRow > 0, @"Number of items must be greater than zero, got: %lu",
                    (unsigned long)itemsPerRow);
  if (self = [super init]) {
    _items = itemsPerRow;
    _matchRow = YES;
  }
  return self;
}

- (instancetype)initWithItemsPerColumn:(NSUInteger)itemsPerColumn {
  LTParameterAssert(itemsPerColumn > 0, @"Number of items must be greater than zero, got: %lu",
                    (unsigned long)itemsPerColumn);
  if (self = [super init]) {
    _items = itemsPerColumn;
    _matchRow = NO;
  }
  return self;
}

- (CGSize)cellSizeForViewSize:(CGSize)viewSize itemSpacing:(CGFloat)itemSpacing
                  lineSpacing:(CGFloat)lineSpacing {
  CGFloat sizeToMatch = self.matchRow ? viewSize.width : viewSize.height;
  CGFloat spacing = self.matchRow ? itemSpacing : lineSpacing;
  CGFloat itemSize = (sizeToMatch - (spacing * (self.items - 1))) / self.items;
  return CGSizeMake(itemSize, itemSize);
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, items: %lu, %@>", self.class, self,
          (unsigned long)self.items, self.matchRow ? @"fit row" : @"fit column"];
}

- (BOOL)isEqual:(PTUGridSizingStrategy *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return self.items == object.items && self.matchRow == object.matchRow;
}

- (NSUInteger)hash {
  return @(self.items).hash ^ @(self.matchRow).hash;
}

@end

NS_ASSUME_NONNULL_END
