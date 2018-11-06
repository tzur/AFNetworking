// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNOpenURLManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNOpenURLManager ()

/// List of OpenURL handlers to call sequentially on each \c -application:openURL:options: call.
@property (readonly, nonatomic) NSArray<id<PTNOpenURLHandler>> *handlers;

@end

@implementation PTNOpenURLManager

- (instancetype)initWithHandlers:(NSArray<id<PTNOpenURLHandler>> *)handlers {
  if (self = [super init]) {
    _handlers = handlers;
  }
  return self;
}

#pragma mark -
#pragma mark PTNOpenURLResponder
#pragma mark -

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(nullable NSDictionary<NSString *, id> *)options {
  for (id<PTNOpenURLHandler> handler in self.handlers) {
    if ([handler application:app openURL:url options:options]) {
      return YES;
    }
  }
  return NO;
}

@end

NS_ASSUME_NONNULL_END
