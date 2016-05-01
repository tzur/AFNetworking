// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+PTNResizingStrategy.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTCGExtensions.h>
#import <LTKit/NSNumber+CGFloat.h>
#import <LTKit/NSURL+Query.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for NSURL serialization, enabling serializing objects as query fields of an \c NSURL
/// and initializing them with an \c NSURL object with the appropriate query items.
@protocol PTNQuerySerialization <NSObject>

/// Initializes this object using the entries in \c query. If the entries in \c query aren't
/// sufficient for the initialization of this object the returned value will be \c nil.
- (instancetype)initWithQuery:(NSDictionary<NSString *, NSString *> *)query;

/// Returns an array of \c NSURLQuery items sufficient to re-initialize this object with an \c NSURL
/// containing the returned query.
- (NSDictionary<NSString *, NSString *> *)serializedQuery;

@end

#pragma mark -
#pragma mark Serializing factory
#pragma mark -

/// Key for the type of resizing strategy codded in to the \c NSURL query.
static NSString * const kResizingStrategyName = @"resizingstrategy";

@implementation NSURL (PTNResizingStrategy)

- (NSURL *)ptn_URLWithResizingStrategy:(id<PTNResizingStrategy>)strategy {
  if (![strategy conformsToProtocol:@protocol(PTNQuerySerialization)]) {
    return self;
  }

  NSDictionary *query = [((id<PTNQuerySerialization>)strategy) serializedQuery];
  return [self lt_URLByAppendingQueryDictionary:query];
}

- (nullable id<PTNResizingStrategy>)ptn_resizingStrategy {
  NSDictionary *query = self.lt_queryDictionary;

  NSString *strategyName = query[kResizingStrategyName];
  if (!strategyName) {
    return nil;
  }

  Class strategy = [[self class] ptn_strategyNameToClassMap][strategyName];
  LTParameterAssert([strategy conformsToProtocol:@protocol(PTNQuerySerialization)], @"Resizing "
                    "strategy encoded in Query: %@ does not confrom to the PTNQuerySerialization "
                    "protocol: %@", query, NSStringFromClass(strategy));

  if (![strategy conformsToProtocol:@protocol(PTNQuerySerialization)]) {
    return nil;
  }

  return [[strategy alloc] initWithQuery:query];
}

+ (LTBidirectionalMap *)ptn_strategyNameToClassMap {
  static LTBidirectionalMap *map;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = [LTBidirectionalMap mapWithDictionary:@{
      @"identity": [PTNIdentityResizingStrategy class],
      @"maxpixels": [PTNMaxPixelsResizingStrategy class],
      @"aspectfit": [PTNAspectFitResizingStrategy class],
      @"aspectfill": [PTNAspectFillResizingStrategy class]
    }];
  });

  return map;
}

@end

#pragma mark -
#pragma mark Utilities
#pragma mark -

static NSString * const kWidthParameter = @"width";
static NSString * const kHeightParameter = @"height";

static NSDictionary<NSString *, NSString *> *PTNQueryFromSize(CGSize size) {
  NSString *heightString = [NSString stringWithFormat:@"%g", size.height];
  NSString *widthString = [NSString stringWithFormat:@"%g", size.width];

  return @{
    kWidthParameter: widthString,
    kHeightParameter: heightString
  };
}

static CGSize PTNSizeFromQuery(NSDictionary<NSString *, NSString *> *query) {
  NSString *widthString = query[kWidthParameter];
  NSString *heightString = query[kHeightParameter];
  if (!widthString || !heightString) {
    return CGSizeNull;
  }

  return CGSizeMake(widthString.floatValue, heightString.floatValue);
}

static NSString *PTNStrategyName(NSObject *startegy) {
  return [[NSURL ptn_strategyNameToClassMap] keyForObject:[startegy class]];
}

#pragma mark -
#pragma mark Identity resizing strategy
#pragma mark -

@interface PTNIdentityResizingStrategy (NSURL) <PTNQuerySerialization>
@end

@implementation PTNIdentityResizingStrategy (NSURL)

static NSString * const kIdentityStrategyName = @"foo";

- (NSDictionary<NSString *, NSString *> *)serializedQuery {
  return @{kResizingStrategyName: PTNStrategyName(self)};
}

- (instancetype)initWithQuery:(NSDictionary<NSString *, NSString *> *)query {
  if (![query[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
    return nil;
  }

  return [[PTNIdentityResizingStrategy alloc] init];
}

@end

#pragma mark -
#pragma mark Max pixels resizing strategy
#pragma mark -

@interface PTNMaxPixelsResizingStrategy (NSURL) <PTNQuerySerialization>
@end

@implementation PTNMaxPixelsResizingStrategy (NSURL)

static NSString * const kMaxPixelsParameter = @"maxpixels";

- (instancetype)initWithQuery:(NSDictionary<NSString *, NSString *> *)query {
  if (![query[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
    return nil;
  }

  NSString *maxPixelsString = query[kMaxPixelsParameter];
  if (!maxPixelsString) {
    return nil;
  }

  unsigned long long maxPixels;
  if (![[NSScanner scannerWithString:maxPixelsString] scanUnsignedLongLong:&maxPixels]) {
    return nil;
  }

  return [self initWithMaxPixels:(unsigned long)maxPixels];
}

- (NSDictionary<NSString *, NSString *> *)serializedQuery {
  NSString *maxPixelsString = [NSString stringWithFormat:@"%lu", (unsigned long)self.maxPixels];

  return @{
    kResizingStrategyName: PTNStrategyName(self),
    kMaxPixelsParameter: maxPixelsString
  };
}

@end

#pragma mark -
#pragma mark Aspect fit resizing strategy
#pragma mark -

@interface PTNAspectFitResizingStrategy (NSURL) <PTNQuerySerialization>
@end

@implementation PTNAspectFitResizingStrategy (NSURL)

- (instancetype)initWithQuery:(NSDictionary<NSString *, NSString *> *)query {
  if (![query[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
    return nil;
  }

  CGSize size = PTNSizeFromQuery(query);
  if (CGSizeIsNull(size)) {
    return nil;
  }

  return [self initWithSize:size];
}

- (NSDictionary<NSString *, NSString *> *)serializedQuery {
  NSMutableDictionary *query = [@{kResizingStrategyName: PTNStrategyName(self)} mutableCopy];
  [query addEntriesFromDictionary:PTNQueryFromSize(self.size)];
  return [query copy];
}

@end

#pragma mark -
#pragma mark Aspect fill resizing strategy
#pragma mark -

@interface PTNAspectFillResizingStrategy (NSURL) <PTNQuerySerialization>
@end

@implementation PTNAspectFillResizingStrategy (NSURL)

- (instancetype)initWithQuery:(NSDictionary<NSString *, NSString *> *)query {
  if (![query[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
    return nil;
  }

  CGSize size = PTNSizeFromQuery(query);
  if (CGSizeIsNull(size)) {
    return nil;
  }

  return [self initWithSize:size];
}

- (NSDictionary<NSString *, NSString *> *)serializedQuery {
  NSMutableDictionary *query = [@{kResizingStrategyName: PTNStrategyName(self)} mutableCopy];
  [query addEntriesFromDictionary:PTNQueryFromSize(self.size)];
  return [query copy];
}

@end

NS_ASSUME_NONNULL_END
