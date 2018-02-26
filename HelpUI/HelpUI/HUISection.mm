// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUISection.h"

#import "HUIItem.h"

NS_ASSUME_NONNULL_BEGIN

@implementation HUISection

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithKey:(NSString *)key title:(NSString * _Nullable)title
                      items:(NSArray<HUIItem *> *)items {
  if (self = [super init]) {
    _key = [key copy];
    _title = [[HUISettings instance] localize:[title copy]];
    _items = [items copy];
  }
  return self;
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(HUISection, key): @"key",
    @instanceKeypath(HUISection, title): @"title",
    @instanceKeypath(HUISection, items): @"items",
  };
}

+ (NSValueTransformer *)itemsJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[HUIItem class]];
}

- (void)setTitle:(NSString *)title {
  _title = [[HUISettings instance] localize:title];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (BOOL)hasTitle {
  return self.title != nil;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSSet<NSString *> *)featureItemTitles {
  auto *sectionTitles = [NSMutableSet<NSString *> set];
  for (HUIItem *item in self.items) {
    if (item.associatedFeatureItemTitles) {
      [sectionTitles addObjectsFromArray:item.associatedFeatureItemTitles];
    }
  }
  return [sectionTitles copy];
}

@end

NS_ASSUME_NONNULL_END
