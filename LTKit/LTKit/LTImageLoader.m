// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageLoader.h"

@interface LTImageLoader ()
@property (strong, nonatomic) Class imageClass;
@end

@implementation LTImageLoader

- (instancetype)init {
  if (self = [super init]) {
    self.imageClass = [UIImage class];
  }
  return self;
}

+ (instancetype)sharedInstance {
  static LTImageLoader *instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTImageLoader alloc] init];
  });

  return instance;
}

- (UIImage *)imageNamed:(NSString *)name {
  return [self.imageClass imageNamed:name];
}

- (UIImage *)imageWithContentsOfFile:(NSString *)name {
  return [self.imageClass imageWithContentsOfFile:name];
}

@end
