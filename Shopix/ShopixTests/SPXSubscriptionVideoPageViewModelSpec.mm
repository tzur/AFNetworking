// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionVideoPageViewModel.h"

SpecBegin(SPXSubscriptionVideoPageViewModel)

__block SPXSubscriptionVideoPageViewModel *videoPageViewModel;
__block id mockApplication;
__block UIWindow *window;
__block NSRange titleRange;
__block NSRange subtitleRange;

beforeEach(^{
  videoPageViewModel = [[SPXSubscriptionVideoPageViewModel alloc]
      initWithVideoURL:[NSURL URLWithString:@""] titleText:@"title" subtitleText:@"subtitle"
                        videoBorderColor:nil titleTextColor:[UIColor redColor]
                        subtitleTextColor:[UIColor blueColor]];
  titleRange = NSMakeRange(0, videoPageViewModel.title.length);
  subtitleRange = NSMakeRange(0, videoPageViewModel.subtitle.length);

  mockApplication = OCMPartialMock([UIApplication sharedApplication]);
  window = OCMClassMock([UIWindow class]);
  OCMStub([mockApplication keyWindow]).andReturn(window);
});

afterEach(^{
  mockApplication = nil;
});

context(@"font size adaptation", ^{
  it(@"should change the title font size according to the screen height", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 500));

    UIFont *titleFont = [videoPageViewModel.title attribute:NSFontAttributeName atIndex:0
                                      longestEffectiveRange:nil inRange:titleRange];
    expect(titleFont.lineHeight).to.equal(23.8671875);
  });

  it(@"should change the subtitle font size according to the screen height", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 800));

    UIFont *subtitleFont = [videoPageViewModel.subtitle attribute:NSFontAttributeName atIndex:0
                                            longestEffectiveRange:nil inRange:subtitleRange];
    expect(subtitleFont.lineHeight).to.equal(18.1390625);
  });

  it(@"should limit the title font size if reached to maximum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 2000));

    UIFont *titleFont = [videoPageViewModel.title attribute:NSFontAttributeName atIndex:0
                                      longestEffectiveRange:nil inRange:titleRange];
    expect(titleFont.lineHeight).to.equal(31.02734375);
  });

  it(@"should limit the subtitle font size if reached to maximum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 2000));

    UIFont *subtitleFont = [videoPageViewModel.subtitle attribute:NSFontAttributeName atIndex:0
                                            longestEffectiveRange:nil inRange:subtitleRange];
    expect(subtitleFont.lineHeight).to.equal(19.09375);
  });

  it(@"should limit the title font size if is below minimum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 0));

    UIFont *titleFont = [videoPageViewModel.title attribute:NSFontAttributeName atIndex:0
                                      longestEffectiveRange:nil inRange:titleRange];
    expect(titleFont.lineHeight).to.equal(21.48046875);
  });

  it(@"should clamp the subtitle font size if is below minimum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 0));

    UIFont *subtitleFont = [videoPageViewModel.subtitle attribute:NSFontAttributeName atIndex:0
                                            longestEffectiveRange:nil inRange:subtitleRange];
    expect(subtitleFont.lineHeight).to.equal(15.513671875);
  });
});

context(@"text colors", ^{
  it(@"should change the title color by the given initializer color", ^{
    UIColor *titleColor = [videoPageViewModel.title attribute:NSForegroundColorAttributeName
                                                      atIndex:0 longestEffectiveRange:nil
                                                      inRange:titleRange];
    expect(titleColor).to.equal([UIColor redColor]);
  });

  it(@"should change the subtitle color by the given initializer color", ^{
    UIColor *subtitleColor = [videoPageViewModel.subtitle attribute:NSForegroundColorAttributeName
                                                            atIndex:0 longestEffectiveRange:nil
                                                            inRange:subtitleRange];
    expect(subtitleColor).to.equal([UIColor blueColor]);
  });
});

SpecEnd
