// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (Photons)

- (NSDictionary<NSString *, NSString *> *)ptn_queryDictionary {
  NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];

  // Last query item name overrides previous ones, if exist.
  NSMutableDictionary *items = [NSMutableDictionary dictionary];
  for (NSURLQueryItem *item in components.queryItems) {
    items[item.name] = item.value;
  }

  return [items copy];
}

@end

NS_ASSUME_NONNULL_END
