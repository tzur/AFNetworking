// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "PTNOceanAssetDescriptor.h"

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

@implementation PTNOceanAssetSizeInfo

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

@implementation PTNOceanAssetDescriptor

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionaryValue
                                      error:(NSError *__autoreleasing *)error {
  if (self = [super initWithDictionary:dictionaryValue error:error]) {
    NSArray *array = dictionaryValue[@"sizes"];

    if (![[[self class] propertyKeys] isEqualToSet:[NSSet setWithArray:dictionaryValue.allKeys]]) {
      if (error) {
        *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                               description:kUnmatchedKeysDescription, dictionaryValue,
                                           [self class]];
      }
      return nil;
    }
    if (!array.count) {
      if (error) {
        *error = [NSError lt_errorWithCode:PTNErrorCodeDeserializationFailed
                               description:@"Provided dictionary %@ must contain non empty sizes "
                                           "array", dictionaryValue];
      }
      return nil;
    }
  }
  return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @"sizes": @"all_sizes",
    @"type": @"asset_type",
    @"source": @"source_id",
    @"identifier": @"id"
  };
}

+ (NSValueTransformer *)typeJSONTransformer {
  return [MTLValueTransformer
          reversibleTransformerWithForwardBlock:^PTNOceanAssetType * _Nullable(NSString *name) {
    if (![name isKindOfClass:[NSString class]]) {
      LogError(@"Expected NSString, got: %@", NSStringFromClass([name class]));
      return nil;
    }
    return [name isEqualToString:@"photo"] ? $(PTNOceanAssetTypePhoto) : nil;
  } reverseBlock:^NSString * _Nullable(id<LTEnum> enumObject) {
    return [enumObject isEqual:$(PTNOceanAssetTypePhoto)] ? @"photo" : nil;
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

+ (NSValueTransformer *)sizesJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[PTNOceanAssetSizeInfo class]];
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
  return [NSSet set];
}

- (NSTimeInterval)duration {
  return 0;
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
