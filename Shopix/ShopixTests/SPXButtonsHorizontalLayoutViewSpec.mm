// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXButtonsHorizontalLayoutView.h"

SpecBegin(SPXButtonsHorizontalLayoutView)

__block SPXButtonsHorizontalLayoutView *horizontalLayoutView;
__block NSArray<UIButton *> *buttons;

beforeEach(^{
  horizontalLayoutView = [[SPXButtonsHorizontalLayoutView alloc] init];
  buttons = @[
    [[UIButton alloc] init],
    [[UIButton alloc] init]
  ];
  horizontalLayoutView.buttons = buttons;
});

context(@"button pressed signal", ^{
  it(@"should send the right pressed button index", ^{
    auto recorder = [horizontalLayoutView.buttonPressed testRecorder];

    [buttons.lastObject sendActionsForControlEvents:UIControlEventTouchUpInside];
    [buttons.firstObject sendActionsForControlEvents:UIControlEventTouchUpInside];
    expect(recorder).to.sendValues(@[@1, @0]);
  });

  it(@"should send the right pressed button index after buttons update", ^{
    horizontalLayoutView.buttons = [buttons mtl_arrayByRemovingFirstObject];
    auto recorder = [horizontalLayoutView.buttonPressed testRecorder];

    [buttons.lastObject sendActionsForControlEvents:UIControlEventTouchUpInside];
    expect(recorder).to.sendValues(@[@0]);
  });
});

context(@"enlarged button index", ^{
  it(@"should raise if the enlarged button index is greater than the last button index", ^{
    expect(^{
      horizontalLayoutView.enlargedButtonIndex = @2;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should set the enlarged index to nil after resetting the buttons", ^{
    horizontalLayoutView.enlargedButtonIndex = @1;
    horizontalLayoutView.buttons = @[];
    expect(horizontalLayoutView.enlargedButtonIndex).to.beNil();
  });
});

SpecEnd
