// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "NSURL+Query.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (Query)

- (NSURL *)lt_URLByAppendingQueryItems:(NSArray<NSURLQueryItem *> *)queryItems {
  if (!queryItems.count) {
    return self;
  }

  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  LTAssert(components, @"Could not parse URL %@", self);

  components.queryItems = [components.queryItems ?: @[] arrayByAddingObjectsFromArray:queryItems];
  return [components URLRelativeToURL:self.baseURL];
}

- (NSURL *)lt_URLByAppendingQueryDictionary:
    (NSDictionary<NSString *, NSString *> *)queryDictionary {
  if (!queryDictionary.count) {
    return self;
  }

  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  LTAssert(components, @"Could not parse URL %@", self);

  NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray array];
  if (components.queryItems) {
    [queryItems addObjectsFromArray:components.queryItems];
  }

  [queryDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value,
                                                       BOOL __unused *stop) {
    LTParameterAssert([key isKindOfClass:NSString.class], @"Keys of queryDictionary must be of "
                      "class NSString only. Found a key %@ with class %@", key, [key class]);
    LTParameterAssert([value isKindOfClass:NSString.class], @"Values of queryDictionary must be of "
                      "class NSString only. Found a value %@ with class %@", value, [value class]);
    [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
  }];

  components.queryItems = queryItems;
  return [components URLRelativeToURL:self.baseURL];
}

- (nullable NSArray<NSURLQueryItem *> *)queryItems {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  return components.queryItems;
}

- (NSDictionary<NSString *, NSString *> *)queryDictionary {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  if (!components) {
    return @{};
  }

  NSMutableDictionary<NSString *, NSString *> *queryDictionary =
      [NSMutableDictionary dictionaryWithCapacity:components.queryItems.count];
  for (NSURLQueryItem *item in components.queryItems) {
    queryDictionary[item.name] = item.value ?: @"";
  }
  return [queryDictionary copy];
}

@end

NS_ASSUME_NONNULL_END
