// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageLoader.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTImageLoader

+ (instancetype)sharedInstance {
  static LTImageLoader *instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTImageLoader alloc] init];
  });

  return instance;
}

- (nullable UIImage *)imageNamed:(NSString *)name {
  return [UIImage imageNamed:name];
}

- (nullable UIImage *)imageWithContentsOfFile:(NSString *)name {
  return [UIImage imageWithContentsOfFile:name];
}

- (nullable UIImage *)imageWithData:(NSData *)data {
  return [UIImage imageWithData:data];
}

@end

NS_ASSUME_NONNULL_END
