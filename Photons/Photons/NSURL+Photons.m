// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (Photons)

+ (PTNQueryDictionary *)ptn_dictionaryWithQuery:(NSArray<NSURLQueryItem *> *)query {
  // Last query item name overrides previous one, if exists.
  NSMutableDictionary *items = [NSMutableDictionary dictionary];
  for (NSURLQueryItem *item in query) {
    items[item.name] = item.value;
  }

  return [items copy];
}

+ (NSArray<NSURLQueryItem *> *)ptn_queryWithDictionary:(PTNQueryDictionary *)dictionary {
  NSMutableArray *items = [NSMutableArray array];
  for (NSString *key in dictionary) {
    NSURLQueryItem *item = [[NSURLQueryItem alloc] initWithName:key value:dictionary[key]];
    [items addObject:item];
  }

  return [items copy];
}

- (NSURL *)ptn_URLByAppendingQuery:(NSArray<NSURLQueryItem *> *)query {
  NSURLComponents *components = [[NSURLComponents alloc] initWithString:self.absoluteString];
  components.queryItems = [components.queryItems ?: @[] arrayByAddingObjectsFromArray:query];
  return components.URL;
}

- (NSDictionary<NSString *, NSString *> *)ptn_queryDictionary {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
  return [[self class] ptn_dictionaryWithQuery:components.queryItems];
}

@end

NS_ASSUME_NONNULL_END
