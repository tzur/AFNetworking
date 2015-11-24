// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSBundle+Path.h"

SpecBegin(NSBundle_Path)

context(@"path for resource near class", ^{
  it(@"should return path for an available resource", ^{
    NSString *path = [NSBundle lt_pathForResource:@"Info.plist" nearClass:self.class];
    expect(path).notTo.beNil();
  });

  it(@"should return nil for non-existing resource", ^{
    NSString *path = [NSBundle lt_pathForResource:@"NonExistingResource.baz.bar"
                                        nearClass:self.class];
    expect(path).to.beNil();
  });
});

context(@"path for resource", ^{
  __block NSBundle *bundle;

  beforeEach(^{
    bundle = [NSBundle bundleForClass:self.class];
  });

  it(@"should return path for an available resource", ^{
    NSString *path = [bundle lt_pathForResource:@"Info.plist"];
    expect(path).notTo.beNil();
  });

  it(@"should return nil for non-existing resource", ^{
    NSString *path = [bundle lt_pathForResource:@"NonExistingResource.baz.bar"];
    expect(path).to.beNil();
  });
});

SpecEnd
