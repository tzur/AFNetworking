// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "NSURL+Ocean.h"

#import <LTKit/NSURL+Query.h>

#import "PTNOceanEnums.h"

NS_ASSUME_NONNULL_BEGIN

/// Possible types of Ocean URLs.
LTEnumImplement(NSUInteger, PTNOceanURLType,
  /// Album URL type.
  PTNOceanURLTypeAlbum,
  /// Asset URL type.
  PTNOceanURLTypeAsset
);

@implementation NSURL (Ocean)

NSString * const kPTNOceanURLQueryItemSourceKey = @"source";
NSString * const kPTNOceanURLQueryItemTypeKey = @"type";
NSString * const kPTNOceanURLQueryItemPhraseKey = @"phrase";
NSString * const kPTNOceanURLQueryItemPageKey = @"page";
NSString * const kPTNOceanURLQueryItemIdentifierKey = @"id";

/// Returns a number formatter that can convert numbers with digits [0-9] to strings and vice-versa.
NSNumberFormatter *PTNLocaleNeutralNumberFormatter() {
  auto formatter = [[NSNumberFormatter alloc] init];
  formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  return formatter;
}

+ (NSString *)ptn_oceanScheme {
  return @"com.lightricks.Photons.Ocean";
}

+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType phrase:(NSString *)phrase {
  return [NSURL ptn_oceanAlbumURLWithSource:source assetType:assetType phrase:phrase page:1];
}

+ (NSURL *)ptn_oceanAlbumURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType phrase:(NSString *)phrase
                                  page:(NSUInteger)page {
  auto components = [[NSURLComponents alloc] init];
  components.scheme = [self ptn_oceanScheme];
  components.host = @"album";

  auto queryItems = @[
    [NSURLQueryItem queryItemWithName:kPTNOceanURLQueryItemSourceKey value:source.name],
    [NSURLQueryItem queryItemWithName:kPTNOceanURLQueryItemTypeKey value:assetType.name],
    [NSURLQueryItem queryItemWithName:kPTNOceanURLQueryItemPhraseKey value:phrase],
    [NSURLQueryItem queryItemWithName:kPTNOceanURLQueryItemPageKey
                                value:[NSString stringWithFormat:@"%lu", (unsigned long)page]]
  ];

  components.queryItems = queryItems;
  return components.URL;
}

+ (NSURL *)ptn_oceanAssetURLWithSource:(PTNOceanAssetSource *)source
                             assetType:(PTNOceanAssetType *)assetType
                            identifier:(NSString *)identifier {
  auto components = [[NSURLComponents alloc] init];
  components.scheme = [self ptn_oceanScheme];
  components.host = @"asset";
  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:kPTNOceanURLQueryItemIdentifierKey value:identifier],
    [NSURLQueryItem queryItemWithName:kPTNOceanURLQueryItemSourceKey value:source.name],
    [NSURLQueryItem queryItemWithName:kPTNOceanURLQueryItemTypeKey value:assetType.name]
  ];
  return components.URL;
}

+ (nullable NSURL *)ptn_oceanAssetURLWithBazaarIdentifier:(NSString *)bazaarIdentifier {
  auto identifierPrefix = [NSString stringWithFormat:@"%@.", [self class].ptn_oceanScheme];
  if (![bazaarIdentifier hasPrefix:identifierPrefix]) {
    return nil;
  }

  auto bazaarIdentifierWithoutPrefix = [bazaarIdentifier
                                        substringFromIndex:identifierPrefix.length];
  auto identifierComponents = [bazaarIdentifierWithoutPrefix componentsSeparatedByString:@"."];
  if (identifierComponents.count != 3) {
    return nil;
  }

  auto _Nullable assetSource = [PTNOceanAssetSource sourceWithIdentifier:identifierComponents[0]];
  auto _Nullable assetType = [PTNOceanAssetType typeWithIdentifier:identifierComponents[1]];
  if (!assetType || !assetSource) {
    return nil;
  }

  return [NSURL ptn_oceanAssetURLWithSource:assetSource assetType:assetType
                                 identifier:identifierComponents[2]];
}

- (nullable PTNOceanURLType *)ptn_oceanURLType {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  if ([self.host isEqualToString:@"album"]) {
    return $(PTNOceanURLTypeAlbum);
  }
  if ([self.host isEqualToString:@"asset"]) {
    return $(PTNOceanURLTypeAsset);
  }
  return nil;
}

- (nullable PTNOceanAssetType *)ptn_oceanAssetType {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  NSString * _Nullable type = [self lt_queryDictionary][kPTNOceanURLQueryItemTypeKey];
  if (!type) {
    return nil;
  }
  return [PTNOceanAssetType enumWithName:type];
}

- (nullable PTNOceanAssetSource *)ptn_oceanAssetSource {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  NSString * _Nullable type = [self lt_queryDictionary][kPTNOceanURLQueryItemSourceKey];
  if (!type) {
    return nil;
  }
  return [PTNOceanAssetSource enumWithName:type];
}

- (nullable NSString *)ptn_oceanSearchPhrase {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  return [self lt_queryDictionary][kPTNOceanURLQueryItemPhraseKey];
}

- (nullable NSNumber *)ptn_oceanPageNumber {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  auto formatter = PTNLocaleNeutralNumberFormatter();
  return [formatter numberFromString:[self lt_queryDictionary][kPTNOceanURLQueryItemPageKey]];
}

- (nullable NSString *)ptn_oceanAssetIdentifier {
  if (![self.scheme isEqualToString:[NSURL ptn_oceanScheme]]) {
    return nil;
  }
  return [self lt_queryDictionary][kPTNOceanURLQueryItemIdentifierKey];
}

- (nullable NSString *)ptn_bazaarIdentifier {
  if (![self.ptn_oceanURLType isEqual:$(PTNOceanURLTypeAsset)]) {
    return nil;
  }

  return [@[
    [self class].ptn_oceanScheme,
    self.ptn_oceanAssetSource.identifier,
    self.ptn_oceanAssetType.identifier,
    self.ptn_oceanAssetIdentifier,
  ] componentsJoinedByString:@"."];
}

@end

NS_ASSUME_NONNULL_END
