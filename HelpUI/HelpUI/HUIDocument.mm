// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIDocument.h"

#import "HUIItem.h"
#import "HUIModelSettings.h"
#import "HUISection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation HUIDocument

#pragma mark -
#pragma mark Initialization
#pragma mark -

+ (nullable instancetype)helpDocumentForJsonAtPath:(nullable NSString *)path
                                             error:(NSError *__autoreleasing *)error {
  if (!path) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound];
    }
    return nil;
  }

  NSError *readError;
  NSData * _Nullable contents = [NSData dataWithContentsOfFile:path options:0 error:&readError];
  if (!contents) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                         underlyingError:readError];
    }
    return nil;
  }

  NSError *deserializationError;
  id _Nullable deserialized = [NSJSONSerialization JSONObjectWithData:contents options:0
                                                                error:&deserializationError];
  if (!deserialized) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                         underlyingError:deserializationError];
    }
    return nil;
  }

  if (![deserialized isKindOfClass:[NSDictionary class]]) {
    if (error) {
      *error = [NSError
                lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                description:@"Expected NSDictionary as root class, got: %@", [deserialized class]];
    }
    return nil;
  }

  return [HUIDocument helpDocumentFromJSONDictionary:deserialized error:error];
}

+ (instancetype)helpDocumentFromJSONDictionary:(NSDictionary *)dictionary
                                         error:(NSError *__autoreleasing *)error {
  return [MTLJSONAdapter modelOfClass:self.class fromJSONDictionary:dictionary error:error];
}

- (instancetype)init {
  if (self = [super init]) {
    _sections = [NSArray array];
  }
  return self;
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(HUIDocument, title): @"title",
    @instanceKeypath(HUIDocument, sections): @"sections",
  };
}

+ (NSValueTransformer *)sectionsJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[HUISection class]];
}

- (void)setTitle:(NSString *)title {
  _title = [HUIModelSettings localize:title];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (nullable HUISection *)sectionForKey:(NSString *)key {
  for (HUISection *section in self.sections) {
    if ([section.key isEqualToString:key]) {
      return section;
    }
  }
  return nil;
}

- (nullable NSString *)sectionKeyForPath:(NSString *)featureHierarchyPath {
  for (NSString *featureItemTitle in featureHierarchyPath.pathComponents) {
    NSString *sectionKey = [self sectionKeyForFeatureItemTitle:featureItemTitle];
    if (sectionKey) {
      return sectionKey;
    }
  }
  return nil;
}

- (nullable NSString *)sectionKeyForFeatureItemTitle:(nullable NSString *)featureItemTitle {
  for (HUISection *section in self.sections) {
    if ([section.featureItemTitles containsObject:featureItemTitle]) {
      return section.key;
    }
  }
  return nil;
}

- (NSSet<NSString *> *)featureItemTitles {
  NSMutableSet<NSString *> *documentTitles = [NSMutableSet set];
  for (HUISection *section in self.sections) {
    [documentTitles unionSet:section.featureItemTitles];
  }
  return [documentTitles copy];
}

@end

NS_ASSUME_NONNULL_END
