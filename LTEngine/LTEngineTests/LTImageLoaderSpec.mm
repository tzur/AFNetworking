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

+ (UIImage *)imageWithContentsOfFile:(NSString *)name {
  if ([self callback]) {
    [self callback](name);
  }
  return nil;
}

@end

SpecBegin(LTImageLoader)

__block NSString *loadedName;
__block LTImageLoader *loader;

beforeEach(^{
  loader = [LTImageLoader sharedInstance];
  loader.imageClass = [LTMyImage class];
  [LTMyImage setCallback:^(NSString *name) {
    loadedName = name;
  }];
});

afterEach(^{
  loadedName = nil;
});

it(@"should load image from main bundle", ^{
  static NSString * const kImageName = @"Boo";
  [loader imageNamed:kImageName];

  expect(loadedName).to.equal(kImageName);
});

it(@"should load image with contents of file", ^{
  static NSString * const kImageName = @"Boo";
  [loader imageWithContentsOfFile:kImageName];

  expect(loadedName).to.equal(kImageName);
});

SpecEnd
