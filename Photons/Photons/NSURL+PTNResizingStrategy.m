// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+PTNResizingStrategy.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTCGExtensions.h>
#import <LTKit/NSNumber+CGFloat.h>

#import "NSURL+Photons.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for NSURL serialization, enabling serializing objects as query fields of an \c NSURL
/// and initializing them with an \c NSURL object with the appropriate query items.
@protocol PTNQuerySerialization <NSObject>

/// Initializes this object using the entries in \c query. If the entries in \c query aren't
/// sufficient for the initialization of this object the returned value will be \c nil.
- (instancetype)initWithQuery:(NSArray<NSURLQueryItem *> *)query;

/// Returns an array of \c NSURLQuery items sufficient to re-initialize this object with an \c NSURL
/// containing the returned query.
- (NSArray<NSURLQueryItem *> *)serializedQuery;

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

  NSArray<NSURLQueryItem *> *query = [((id<PTNQuerySerialization>)strategy) serializedQuery];
  return [self ptn_URLByAppendingQuery:query];
}

- (nullable id<PTNResizingStrategy>)ptn_resizingStrategy {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  NSArray<NSURLQueryItem *> *query = components.queryItems;

  NSString *strategyName = self.ptn_queryDictionary[kResizingStrategyName];
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

static NSArray<NSURLQueryItem *> *PTNQueryFromSize(CGSize size) {
  NSString *heightString = [NSString stringWithFormat:@"%g", size.height];
  NSString *widthString = [NSString stringWithFormat:@"%g", size.width];

  return @[
    [[NSURLQueryItem alloc] initWithName:kWidthParameter value:widthString],
    [[NSURLQueryItem alloc] initWithName:kHeightParameter value:heightString]
  ];
}

static CGSize PTNSizeFromQuery(NSArray<NSURLQueryItem *> *query) {
  NSDictionary *queryDict = [NSURL ptn_dictionaryWithQuery:query];

  NSString *widthString = queryDict[kWidthParameter];
  NSString *heightString = queryDict[kHeightParameter];
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

- (NSArray<NSURLQueryItem *> *)serializedQuery {
  return @[[[NSURLQueryItem alloc] initWithName:kResizingStrategyName value:PTNStrategyName(self)]];
}

- (instancetype)initWithQuery:(NSArray<NSURLQueryItem *> *)query {
  NSDictionary *queryDict = [NSURL ptn_dictionaryWithQuery:query];
  if (![queryDict[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
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

- (instancetype)initWithQuery:(NSArray<NSURLQueryItem *> *)query {
  NSDictionary *queryDict = [NSURL ptn_dictionaryWithQuery:query];
  if (![queryDict[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
    return nil;
  }

  NSString *maxPixelsString = queryDict[kMaxPixelsParameter];
  if (!maxPixelsString) {
    return nil;
  }

  unsigned long long maxPixels;
  if (![[NSScanner scannerWithString:maxPixelsString] scanUnsignedLongLong:&maxPixels]) {
    return nil;
  }

  return [self initWithMaxPixels:(unsigned long)maxPixels];
}

- (NSArray<NSURLQueryItem *> *)serializedQuery {
  NSString *maxPixelsString = [NSString stringWithFormat:@"%lu", (unsigned long)self.maxPixels];

  return @[
    [[NSURLQueryItem alloc] initWithName:kResizingStrategyName value:PTNStrategyName(self)],
    [[NSURLQueryItem alloc] initWithName:kMaxPixelsParameter value:maxPixelsString]
  ];
}

@end

#pragma mark -
#pragma mark Aspect fit resizing strategy
#pragma mark -

@interface PTNAspectFitResizingStrategy (NSURL) <PTNQuerySerialization>
@end

@implementation PTNAspectFitResizingStrategy (NSURL)

- (instancetype)initWithQuery:(NSArray<NSURLQueryItem *> *)query {
  NSDictionary *queryDict = [NSURL ptn_dictionaryWithQuery:query];
  if (![queryDict[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
    return nil;
  }

  CGSize size = PTNSizeFromQuery(query);
  if (CGSizeIsNull(size)) {
    return nil;
  }

  return [self initWithSize:size];
}

- (NSArray<NSURLQueryItem *> *)serializedQuery {
  NSArray *query = @[[[NSURLQueryItem alloc] initWithName:kResizingStrategyName
                                                    value:PTNStrategyName(self)]];

  return [query arrayByAddingObjectsFromArray:PTNQueryFromSize(self.size)];
}

@end

#pragma mark -
#pragma mark Aspect fill resizing strategy
#pragma mark -

@interface PTNAspectFillResizingStrategy (NSURL) <PTNQuerySerialization>
@end

@implementation PTNAspectFillResizingStrategy (NSURL)

- (instancetype)initWithQuery:(NSArray<NSURLQueryItem *> *)query {
  NSDictionary *queryDict = [NSURL ptn_dictionaryWithQuery:query];
  if (![queryDict[kResizingStrategyName] isEqualToString:PTNStrategyName(self)]) {
    return nil;
  }

  CGSize size = PTNSizeFromQuery(query);
  if (CGSizeIsNull(size)) {
    return nil;
  }

  return [self initWithSize:size];
}

- (NSArray<NSURLQueryItem *> *)serializedQuery {
  NSArray *query = @[[[NSURLQueryItem alloc] initWithName:kResizingStrategyName
                                                    value:PTNStrategyName(self)]];

  return [query arrayByAddingObjectsFromArray:PTNQueryFromSize(self.size)];
}

@end

NS_ASSUME_NONNULL_END
