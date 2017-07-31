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
  return nn([components URLRelativeToURL:self.baseURL]);
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
    [queryItems addObjectsFromArray:components.queryItems ?: @[]];
  }

  [queryDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value,
                                                       BOOL *) {
    LTParameterAssert([key isKindOfClass:NSString.class], @"Keys of queryDictionary must be of "
                      "class NSString only. Found a key %@ with class %@", key, [key class]);
    LTParameterAssert([value isKindOfClass:NSString.class], @"Values of queryDictionary must be of "
                      "class NSString only. Found a value %@ with class %@", value, [value class]);
    [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
  }];

  components.queryItems = queryItems;
  return nn([components URLRelativeToURL:self.baseURL]);
}

- (NSURL *)lt_URLByAppendingQueryArrayDictionary:
    (NSDictionary<NSString *, NSArray<NSString *> *> *)queryArrayDictionary {
  if (!queryArrayDictionary.count) {
    return self;
  }

  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  LTAssert(components, @"Could not parse URL %@", self);

  NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray array];
  if (components.queryItems) {
    [queryItems addObjectsFromArray:components.queryItems ?: @[]];
  }

  [queryArrayDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                            NSArray<NSString *> *arrayValue,
                                                            BOOL *) {
    LTParameterAssert([key isKindOfClass:NSString.class], @"Keys of queryArrayDictionary must be "
                      "of class NSString only. Found a key %@ with class %@", key, [key class]);
    LTParameterAssert([arrayValue isKindOfClass:NSArray.class], @"Values of queryArrayDictionary "
                      "must be of class NSArray only. Found a value %@ with class %@", arrayValue,
                      [arrayValue class]);
    LTParameterAssert(arrayValue.count, @"Values of queryArrayDictionary must have at least one "
                      "entry, but empty array given for key: %@", key);
    for (NSString *value in arrayValue) {
      LTParameterAssert([value isKindOfClass:NSString.class], @"Values of items in "
                        "queryArrayDictionary items must be of class NSString only. Found a value "
                        "%@ with class %@", value, [value class]);
      [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }
  }];

  components.queryItems = queryItems;
  return nn([components URLRelativeToURL:self.baseURL]);
}

- (nullable NSArray<NSURLQueryItem *> *)lt_queryItems {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  return components.queryItems;
}

- (NSDictionary<NSString *, NSString *> *)lt_queryDictionary {
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

- (NSDictionary<NSString *, NSArray<NSString *> *> *)lt_queryArrayDictionary {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  if (!components) {
    return @{};
  }

  NSMutableDictionary<NSString *, NSArray<NSString *> *> *queryDictionary =
      [NSMutableDictionary dictionaryWithCapacity:components.queryItems.count];
  for (NSURLQueryItem *item in components.queryItems) {
    NSArray *queryArray = queryDictionary[item.name] ?: @[];
    queryDictionary[item.name] = [queryArray arrayByAddingObject:item.value ?: @""];
  }
  return [queryDictionary copy];
}

@end

NS_ASSUME_NONNULL_END
