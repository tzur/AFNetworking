// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsPageViewModel.h"

#import <LTKit/NSArray+Functional.h>

#import "SPXSubscriptionDescriptor.h"

SpecBegin(SPXSubscriptionButtonsPageViewModel)

__block SPXSubscriptionButtonsPageViewModel *buttonsPageViewModel;
__block id mockApplication;
__block UIWindow *window;
__block NSRange titleRange;
__block NSRange subtitleRange;

beforeEach(^{
  buttonsPageViewModel = [[SPXSubscriptionButtonsPageViewModel alloc]
      initWithTitleText:@"title" subtitleText:@"subtitle" productIdentifiers:@[@"foo", @"boo"]
      highlightedButtonIndex:nil backgroundVideoURL:[NSURL URLWithString:@""]
      titleTextColor:[UIColor redColor] subtitleTextColor:[UIColor blueColor]];
  titleRange = NSMakeRange(0, buttonsPageViewModel.title.length);
  subtitleRange = NSMakeRange(0, buttonsPageViewModel.subtitle.length);

  mockApplication = OCMPartialMock([UIApplication sharedApplication]);
  window = OCMClassMock([UIWindow class]);
  OCMStub([mockApplication keyWindow]).andReturn(window);
});

afterEach(^{
  mockApplication = nil;
});

it(@"should set the product descriptors according to the product identifiers", ^{
  expect([buttonsPageViewModel.subscriptionDescriptors
          lt_map:^id(SPXSubscriptionDescriptor *descriptor) {
    return descriptor.productIdentifier;
  }]).to.equal(@[@"foo", @"boo"]);
});

it(@"should raise if the highlighted button index is greater than the number of buttons", ^{
  expect(^{
  buttonsPageViewModel = [[SPXSubscriptionButtonsPageViewModel alloc]
      initWithTitleText:@"title" subtitleText:@"subtitle" productIdentifiers:@[@"foo", @"boo"]
      highlightedButtonIndex:@2 backgroundVideoURL:[NSURL URLWithString:@""]
      titleTextColor:[UIColor redColor] subtitleTextColor:[UIColor blueColor]];
  }).to.raise(NSInvalidArgumentException);
});

context(@"font size adaptation", ^{
  it(@"should limit the title font size if reached to maximum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 2000));

    UIFont *titleFont = [buttonsPageViewModel.title attribute:NSFontAttributeName atIndex:0
                                      longestEffectiveRange:nil inRange:titleRange];
    expect(titleFont.lineHeight).to.beCloseToWithin([UIFont systemFontOfSize:32].lineHeight, 0.001);
  });

  it(@"should limit the subtitle font size if reached to maximum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 2000));

    UIFont *subtitleFont = [buttonsPageViewModel.subtitle attribute:NSFontAttributeName atIndex:0
                                            longestEffectiveRange:nil inRange:subtitleRange];
    expect(subtitleFont.lineHeight).to.beCloseToWithin([UIFont systemFontOfSize:22].lineHeight,
                                                       0.001);
  });

  it(@"should clamp the title font size if is below minimum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 0));

    UIFont *titleFont = [buttonsPageViewModel.title attribute:NSFontAttributeName atIndex:0
                                      longestEffectiveRange:nil inRange:titleRange];
    expect(titleFont.lineHeight).to.beCloseToWithin([UIFont systemFontOfSize:16].lineHeight, 0.001);
  });

  it(@"should clamp the subtitle font size if is below minimum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 0));

    UIFont *subtitleFont = [buttonsPageViewModel.subtitle attribute:NSFontAttributeName atIndex:0
                                            longestEffectiveRange:nil inRange:subtitleRange];
    expect(subtitleFont.lineHeight).to.beCloseToWithin([UIFont systemFontOfSize:13].lineHeight,
                                                       0.001);
  });
});

context(@"text colors", ^{
  it(@"should change the title color by the given initializer color", ^{
    UIColor *titleColor = [buttonsPageViewModel.title attribute:NSForegroundColorAttributeName
                                                      atIndex:0 longestEffectiveRange:nil
                                                      inRange:titleRange];
    expect(titleColor).to.equal([UIColor redColor]);
  });

  it(@"should change the subtitle color by the given initializer color", ^{
    UIColor *subtitleColor = [buttonsPageViewModel.subtitle attribute:NSForegroundColorAttributeName
                                                            atIndex:0 longestEffectiveRange:nil
                                                            inRange:subtitleRange];
    expect(subtitleColor).to.equal([UIColor blueColor]);
  });
});

context(@"background video", ^{
  it(@"should change isPlaying to YES when play video is invoked", ^{
    auto recorder = [RACObserve(buttonsPageViewModel, shouldPlayVideo) testRecorder];

    [buttonsPageViewModel playVideo];

    expect(recorder).to.sendValues(@[@NO, @YES]);
  });

  it(@"should change isPlaying to NO when stop video is invoked", ^{
    auto recorder = [RACObserve(buttonsPageViewModel, shouldPlayVideo) testRecorder];

    [buttonsPageViewModel stopVideo];

    expect(recorder).to.sendValues(@[@NO, @NO]);
  });
});

SpecEnd
