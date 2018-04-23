// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetDescriptor.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTKeyPathCoding.h>
#import <LTKit/NSArray+NSSet.h>
#import <Mantle/Mantle.h>

#import "NSErrorCodes+Photons.h"
#import "NSURL+Ocean.h"
#import "NSValueTransformer+Photons.h"
#import "PTNOceanEnums.h"

NS_ASSUME_NONNULL_BEGIN

/// Description for error occured when the keys of a dictionary given upon initialization has keys
/// that do not match the \c propertyKeys of the \c MTLModel subclass.
static NSString * const kUnmatchedKeysDescription =
    @"Keys of the provided dictionary %@ do not match the the property keys of %@";

@implementation PTNOceanImageAssetInfo

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                                      error:(NSError *__autoreleasing *)error {
  if (self = [super initWithDictionary:dictionaryValue error:error]) {
    if (![[[self class] propertyKeys] isEqualToSet:[NSSet setWithArray:dictionaryValue.allKeys]]) {
      if (error) {
        *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                               description:kUnmatchedKeysDescription, dictionaryValue,
                                           [self class]];
      }
      return nil;
    }
  }
  return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @"height": @"height",
    @"width": @"width",
    @"url": @"url"
  };
}

+ (NSValueTransformer *)urlJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kPTNURLValueTransformer];
}

@end

@implementation PTNOceanVideoAssetInfo

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                                      error:(NSError *__autoreleasing *)error {
  if (self = [super initWithDictionary:dictionaryValue error:error]) {
    if (![[[self class] propertyKeys] isEqualToSet:[NSSet setWithArray:dictionaryValue.allKeys]]) {
      if (error) {
        *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                               description:kUnmatchedKeysDescription, dictionaryValue,
                                           [self class]];
      }
      return nil;
    }
  }
  return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @"height": @"height",
    @"width": @"width",
    @"url": @"download_url",
    @"streamURL": @"streaming_url",
    @"size": @"size",
  };
}

+ (NSValueTransformer *)urlJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kPTNURLValueTransformer];
}

+ (NSValueTransformer *)streamURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kPTNURLValueTransformer];
}

@end

@implementation PTNOceanAssetDescriptor

@synthesize duration = _duration;

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                             error:(NSError *__autoreleasing *)error {
  if (self = [super initWithDictionary:dictionaryValue error:error]) {
    if (![self validateDictionary:dictionaryValue error:error]) {
      return nil;
    }

    if (!_videos) {
      _videos = @[];
    }
  }
  return self;
}

- (BOOL)validateDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
  static auto imageMandatoryPropeties = @[
    @keypath(self, identifier),
    @keypath(self, source),
    @keypath(self, type),
    @keypath(self, images)
  ];

  static auto videoMandatoryPropeties = [imageMandatoryPropeties arrayByAddingObjectsFromArray:@[
    @keypath(self, videos),
    @keypath(self, duration)
  ]];

  NSArray *mandatoryProperties;
  if ([self.type isEqual:$(PTNOceanAssetTypePhoto)]) {
    mandatoryProperties = imageMandatoryPropeties;
  } else if ([self.type isEqual:$(PTNOceanAssetTypeVideo)]) {
    mandatoryProperties = videoMandatoryPropeties;
  } else {
    if (error) {
      *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                             description:@"Unknown Ocean asset type %@", self.type];
      return NO;
    }
  }

  if (![[mandatoryProperties lt_set] isSubsetOfSet:[NSSet setWithArray:dictionaryValue.allKeys]]) {
    if (error) {
      *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                             description:kUnmatchedKeysDescription, dictionaryValue, [self class]];
    }
    return NO;
  }

  if (!self.images.count) {
    if (error) {
      *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                             description:@"Provided dictionary %@ must contain at least one image" ,
                                         dictionaryValue];
    }
    return NO;
  }

  if ([self.type isEqual:$(PTNOceanAssetTypeVideo)]) {
    if (!self.videos.count) {
      if (error) {
        *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                               description:@"Provided dictionary %@ must contain at least one "
                                           "video", dictionaryValue];
      }
      return NO;
    }
  }

  return YES;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(PTNOceanAssetDescriptor, images): @"all_sizes",
    @instanceKeypath(PTNOceanAssetDescriptor, duration): @"duration",
    @instanceKeypath(PTNOceanAssetDescriptor, videos): @"videos",
    @instanceKeypath(PTNOceanAssetDescriptor, type): @"asset_type",
    @instanceKeypath(PTNOceanAssetDescriptor, source): @"source_id",
    @instanceKeypath(PTNOceanAssetDescriptor, identifier): @"id"
  };
}

+ (NSValueTransformer *)typeJSONTransformer {
  static LTBidirectionalMap *assetTypes = [LTBidirectionalMap mapWithDictionary:@{
    @"photo": $(PTNOceanAssetTypePhoto),
    @"video": $(PTNOceanAssetTypeVideo)
  }];

  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^PTNOceanAssetType * _Nullable(NSString *name) {
    if (![name isKindOfClass:[NSString class]]) {
      LogError(@"Expected NSString, got: %@", NSStringFromClass([name class]));
      return nil;
    }
    return assetTypes[name];
  } reverseBlock:^NSString * _Nullable(id<LTEnum> enumObject) {
    return [assetTypes keyForObject:enumObject];
  }];
}

+ (NSValueTransformer *)sourceJSONTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
      ^PTNOceanAssetSource * _Nullable(NSString *name) {
    for (PTNOceanAssetSource *source in [PTNOceanAssetSource fields]) {
      if ([source.identifier isEqualToString:name]) {
        return source;
      }
    }
    return nil;
  } reverseBlock:^NSString * _Nullable(PTNOceanAssetSource *source) {
    return source.identifier;
  }];
}

+ (NSValueTransformer *)imagesJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[PTNOceanImageAssetInfo class]];
}

+ (NSValueTransformer *)videosJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[PTNOceanVideoAssetInfo class]];
}

#pragma mark -
#pragma mark PTNAssetDescriptor
#pragma mark -

- (NSURL *)ptn_identifier {
  return [NSURL ptn_oceanAssetURLWithSource:self.source identifier:self.identifier];
}

- (nullable NSString *)localizedTitle {
  return nil;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  auto traits = [NSMutableSet setWithObject:kPTNDescriptorTraitCloudBasedKey];
  if ([self.type isEqual:$(PTNOceanAssetTypeVideo)]) {
    [traits addObject:kPTNDescriptorTraitAudiovisualKey];
  }
  return traits;
}

- (PTNAssetDescriptorCapabilities)assetDescriptorCapabilities {
  return PTNAssetDescriptorCapabilityNone;
}

- (nullable NSDate *)creationDate {
  return nil;
}

- (nullable NSDate *)modificationDate {
  return nil;
}

- (nullable NSString *)filename {
  return nil;
}

@end

NS_ASSUME_NONNULL_END
