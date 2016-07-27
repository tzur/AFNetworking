// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIShootButton.h"

SpecBegin(CUIShootButton)

__block NSArray *drawers;
__block CUIShootButton *button;

beforeEach(^{
  drawers = @[
    OCMProtocolMock(@protocol(CUIShootButtonDrawer)),
    OCMProtocolMock(@protocol(CUIShootButtonDrawer))
  ];
  button = [[CUIShootButton alloc] initWithDrawers:drawers];
});

context(@"initialization", ^{
  it(@"should raise an exception when initialized with nil drawers", ^{
    NSArray *drawers = nil;
    expect(^{
      CUIShootButton * __unused button = [[CUIShootButton alloc] initWithDrawers:drawers];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"drawRect", ^{
  it(@"should call the drawers in the right order", ^{
    __block NSMutableArray *calledDrawers = [[NSMutableArray alloc] init];
    OCMStub([drawers[0] drawToButton:button]).andDo(^(id) {
      [calledDrawers addObject:drawers[0]];
    });
    OCMStub([drawers[1] drawToButton:button]).andDo(^(id) {
      [calledDrawers addObject:drawers[1]];
    });

    [button drawRect:CGRectZero];

    expect(drawers).to.equal(calledDrawers);
  });
});

context(@"progress", ^{
  it(@"should raise an exception when given negative value", ^{
    expect(^{
      button.progress = -0.01;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when given value bigger than 1", ^{
    expect(^{
      button.progress = 1.01;
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"alpha", ^{
  static const CGFloat kHighlightedAlpha = 0.4;

  beforeEach(^{
    button.highlightedAlpha = kHighlightedAlpha;
  });

  it(@"should use highlighted alpha", ^{
    expect(button.alpha).to.equal(1);
    button.highlighted = YES;
    expect(button.alpha).to.beCloseTo(kHighlightedAlpha);
    button.highlighted = NO;
    expect(button.alpha).to.equal(1);
  });

  it(@"should not change alpha while not highlighted", ^{
    expect(button.alpha).to.equal(1);
    button.highlightedAlpha = kHighlightedAlpha;
    expect(button.alpha).to.equal(1);
  });

  it(@"should change alpha while highlighted", ^{
    button.highlighted = YES;
    expect(button.alpha).to.beCloseTo(kHighlightedAlpha);
    button.highlightedAlpha = 0.6;
    expect(button.alpha).to.beCloseTo(0.6);
  });
});

SpecEnd
