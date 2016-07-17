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

SpecEnd
