// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIImage+Loading.h"

#import "LTDevice.h"
#import "LTTestModule.h"

SpecBegin(UIImageLoading)

LTKitTestsUseObjection();

context(@"image names", ^{
  it(@"should return names in correct order for 4-inch portrait iphone", ^{
    [[[module.ltDevice stub] andReturnValue:@YES] has4InchScreen];
    [[[module.ltDevice stub] andReturnValue:@NO] isPadIdiom];
    [[[module.ltDevice stub] andReturnValue:@YES] isPhoneIdiom];
    [[[module.uiApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
     statusBarOrientation];

    NSArray *expectedNames = @[
      @"a-568h-Portrait@2x~iphone",
      @"a-568h@2x~iphone",
      @"a-Portrait@2x~iphone",
      @"a@2x~iphone",
      @"a-568h@2x",
      @"a@2x",
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
    [[[module.ltDevice stub] andReturnValue:@YES] has4InchScreen];
    [[[module.ltDevice stub] andReturnValue:@NO] isPadIdiom];
    [[[module.ltDevice stub] andReturnValue:@YES] isPhoneIdiom];
    [[[module.uiApplication stub] andReturnValue:@(UIInterfaceOrientationLandscapeLeft)]
     statusBarOrientation];

    NSArray *expectedNames = @[
      @"a-568h-Landscape@2x~iphone",
      @"a-568h@2x~iphone",
      @"a-Landscape@2x~iphone",
      @"a@2x~iphone",
      @"a-568h@2x",
      @"a@2x",
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
    [[[module.ltDevice stub] andReturnValue:@NO] has4InchScreen];
    [[[module.ltDevice stub] andReturnValue:@NO] isPadIdiom];
    [[[module.ltDevice stub] andReturnValue:@YES] isPhoneIdiom];
    [[[module.uiApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
     statusBarOrientation];

    NSArray *expectedNames = @[
      @"a-Portrait@2x~iphone",
      @"a@2x~iphone",
      @"a@2x",
      @"a-Portrait~iphone",
      @"a~iphone",
      @"a"
    ];

    expect([UIImage imageNamesForBasicName:@"a"]).to.equal(expectedNames);
  });

  it(@"should return names in correct order for ipad", ^{
    [[[module.ltDevice stub] andReturnValue:@NO] has4InchScreen];
    [[[module.ltDevice stub] andReturnValue:@YES] isPadIdiom];
    [[[module.ltDevice stub] andReturnValue:@NO] isPhoneIdiom];
    [[[module.uiApplication stub] andReturnValue:@(UIInterfaceOrientationPortrait)]
     statusBarOrientation];

    NSArray *expectedNames = @[
      @"a-Portrait@2x~ipad",
      @"a@2x~ipad",
      @"a@2x",
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

SpecEnd
