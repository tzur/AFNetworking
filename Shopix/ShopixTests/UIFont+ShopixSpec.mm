// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "UIFont+Shopix.h"

SpecBegin(UIFont_Shopix)

__block id mockApplication;
__block UIWindow *window;
__block UIFont *nativeSizeFont;

beforeEach(^{
  mockApplication = OCMPartialMock([UIApplication sharedApplication]);
  window = OCMClassMock([UIWindow class]);
  OCMStub([mockApplication keyWindow]).andReturn(window);
  nativeSizeFont = [UIFont systemFontOfSize:1 weight:UIFontWeightRegular];
});

afterEach(^{
  mockApplication = nil;
});

context(@"font size adaptation", ^{
  it(@"should create font with size according to the screen height", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 300));
    auto font = [UIFont spx_fontWithSizeRatio:0.05 minSize:11 maxSize:16
                                       weight:UIFontWeightRegular];

    expect(font.lineHeight).to.equal(nativeSizeFont.lineHeight * 300 * 0.05);
  });

  it(@"should limit the font size if reached to maximum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 2000));
    auto font = [UIFont spx_fontWithSizeRatio:0.05 minSize:11 maxSize:16
                                       weight:UIFontWeightRegular];

    expect(font.lineHeight).to.equal(nativeSizeFont.lineHeight * 16);
  });

  it(@"should limit the font size if is below minimum", ^{
    OCMStub([window bounds]).andReturn(CGRectMake(0, 0, 0, 0));
    auto font = [UIFont spx_fontWithSizeRatio:0.05 minSize:11 maxSize:16
                                       weight:UIFontWeightRegular];

    expect(font.lineHeight).to.equal(nativeSizeFont.lineHeight * 11);
  });
});

SpecEnd
