// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIImage+Loading.h"

#import "LTDevice.h"

LTSpecBegin(UIImageLoading)

context(@"image names", ^{
  __block id ltDevice;
  __block id uiApplication;
  __block NSString *iphoneSuffix;
  __block NSString *ipadSuffix;
  __block NSString *suffix;

  beforeEach(^{
    ltDevice = LTMockClass([LTDevice class]);
    uiApplication = LTMockClass([UIApplication class]);
    NSUInteger scale = std::round([UIScreen mainScreen].scale);
    iphoneSuffix = [NSString stringWithFormat:@"%lux~iphone", scale];
    ipadSuffix = [NSString stringWithFormat:@"%lux~ipad", scale];
    suffix = [NSString stringWithFormat:@"%lux", scale];
  });

  it(@"should return names in correct order for 4-inch portrait iphone", ^{
    [[[ltDevice stub] andReturnValue:@YES] has4InchScreen];
    [[[ltDevice stub] andReturnValue:@NO] isPadIdiom];
    [[[ltDevice stub] andReturnValue:@YES] isPhoneIdiom];
    [[[uiApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)] statusBarOrientation];

    NSArray *expectedNames = @[
      [@"a-568h-Portrait@" stringByAppendingString:iphoneSuffix],
      [@"a-568h@" stringByAppendingString:iphoneSuffix],
      [@"a-Portrait@" stringByAppendingString:iphoneSuffix],
      [@"a@" stringByAppendingString:iphoneSuffix],
      [@"a-568h@" stringByAppendingString:suffix],
      [@"a@" stringByAppendingString:suffix],
      @"a-568h-Portrait~iphone",
      @"a-568h~iphone",
      @"a-Portrait~iphone",
      @"a~iphone",
      @"a-568h",
      @"a"
    ];

    expect([UIImage imageNamesForBasicName:@"a"]).to.equal(expectedNames);
  });

  it(@"should return names in correct order for 4-inch landscape iphone", ^{
    [[[ltDevice stub] andReturnValue:@YES] has4InchScreen];
    [[[ltDevice stub] andReturnValue:@NO] isPadIdiom];
    [[[ltDevice stub] andReturnValue:@YES] isPhoneIdiom];
    [[[uiApplication stub] andReturnValue:@(UIInterfaceOrientationLandscapeLeft)]
     statusBarOrientation];

    NSArray *expectedNames = @[
      [@"a-568h-Landscape@" stringByAppendingString:iphoneSuffix],
      [@"a-568h@" stringByAppendingString:iphoneSuffix],
      [@"a-Landscape@" stringByAppendingString:iphoneSuffix],
      [@"a@" stringByAppendingString:iphoneSuffix],
      [@"a-568h@" stringByAppendingString:suffix],
      [@"a@" stringByAppendingString:suffix],
      @"a-568h-Landscape~iphone",
      @"a-568h~iphone",
      @"a-Landscape~iphone",
      @"a~iphone",
      @"a-568h",
      @"a"
    ];

    expect([UIImage imageNamesForBasicName:@"a"]).to.equal(expectedNames);
  });

  it(@"should return names in correct order for 3.5-inch portrait iphone", ^{
    [[[ltDevice stub] andReturnValue:@NO] has4InchScreen];
    [[[ltDevice stub] andReturnValue:@NO] isPadIdiom];
    [[[ltDevice stub] andReturnValue:@YES] isPhoneIdiom];
    [[[uiApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)] statusBarOrientation];

    NSArray *expectedNames = @[
      [@"a-Portrait@" stringByAppendingString:iphoneSuffix],
      [@"a@" stringByAppendingString:iphoneSuffix],
      [@"a@" stringByAppendingString:suffix],
      @"a-Portrait~iphone",
      @"a~iphone",
      @"a"
    ];

    expect([UIImage imageNamesForBasicName:@"a"]).to.equal(expectedNames);
  });

  it(@"should return names in correct order for ipad", ^{
    [[[ltDevice stub] andReturnValue:@NO] has4InchScreen];
    [[[ltDevice stub] andReturnValue:@YES] isPadIdiom];
    [[[ltDevice stub] andReturnValue:@NO] isPhoneIdiom];
    [[[uiApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)] statusBarOrientation];

    NSArray *expectedNames = @[
      [@"a-Portrait@" stringByAppendingString:ipadSuffix],
      [@"a@" stringByAppendingString:ipadSuffix],
      [@"a@" stringByAppendingString:suffix],
      @"a-Portrait~ipad",
      @"a~ipad",
      @"a"
    ];

    expect([UIImage imageNamesForBasicName:@"a"]).to.equal(expectedNames);
  });
});

context(@"image loading", ^{
  static NSString * const kNonExistingFile = @"__nonExistingFile";
  __block id bundle;

  beforeEach(^{
    bundle = [OCMockObject mockForClass:[NSBundle class]];
  });

  it(@"should try to load files from bundle", ^{
    __block NSMutableArray *files = [NSMutableArray array];
    [[[bundle stub] andDo:^(NSInvocation *invocation) {
      NSString __unsafe_unretained *name;
      NSString __unsafe_unretained *extension;

      [invocation getArgument:&name atIndex:2];
      [invocation getArgument:&extension atIndex:3];
      [files addObject:[name copy]];

      expect(extension).to.equal(@"png");
    }] pathForResource:OCMOCK_ANY ofType:OCMOCK_ANY];

    NSString *path = [UIImage imagePathForName:kNonExistingFile fromBundle:bundle];

    expect(path).to.beNil();
    expect(files).to.equal([UIImage imageNamesForBasicName:kNonExistingFile]);
  });

  it(@"should return first exisitng file from bundle", ^{
    NSString *file = [kNonExistingFile stringByAppendingPathExtension:@"png"];
    [[[bundle stub] andReturn:file] pathForResource:kNonExistingFile ofType:@"png"];
    [[[bundle stub] andReturn:nil] pathForResource:OCMOCK_ANY ofType:OCMOCK_ANY];

    NSString *path = [UIImage imagePathForName:kNonExistingFile fromBundle:bundle];

    expect(path).to.equal(file);
  });
});

LTSpecEnd
