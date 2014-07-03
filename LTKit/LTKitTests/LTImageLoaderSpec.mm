// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageLoader.h"

@interface LTImageLoader ()
@property (strong, nonatomic) Class imageClass;
@end

@interface LTMyImage : NSObject

typedef void (^LTImageNamedCallback)(NSString *name);

+ (void)setCallback:(LTImageNamedCallback)block;

+ (LTImageNamedCallback)callback;

+ (UIImage *)imageNamed:(NSString *)name;

@end

@implementation LTMyImage

static LTImageNamedCallback callback;

+ (void)setCallback:(LTImageNamedCallback)block {
  callback = [block copy];
}

+ (LTImageNamedCallback)callback {
  return callback;
}

+ (UIImage *)imageNamed:(NSString *)name {
  if ([self callback]) {
    [self callback](name);
  }
  return nil;
}

@end

SpecBegin(LTImageLoader)

it(@"should load image from main bundle", ^{
  __block NSString *loadedName;

  LTImageLoader *loader = [LTImageLoader sharedInstance];
  loader.imageClass = [LTMyImage class];
  [LTMyImage setCallback:^(NSString *name) {
    loadedName = name;
  }];

  static NSString * const kImageName = @"Boo";
  [loader imageNamed:kImageName];

  expect(loadedName).to.equal(kImageName);
});

SpecEnd
