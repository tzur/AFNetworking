// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownMenuItemsEntry.h"

#import "CUIMenuItemIconButton.h"
#import "CUIMenuItemTextButton.h"
#import "CUISimpleMenuItemViewModel.h"
#import "CUITheme.h"
#import "UIView+Retrieval.h"

SpecBegin(CUIDropDownMenuItemsEntry)

__block CUIDropDownMenuItemsEntry *entry;
__block CUISimpleMenuItemViewModel *model;
__block Class mainBarViewClass;
__block Class subitemViewClass;

beforeEach(^{
  LTMockClass([CUITheme class]);
  model = [[CUISimpleMenuItemViewModel alloc] init];
  model.subitems= @[
    [[CUISimpleMenuItemViewModel alloc] init],
    [[CUISimpleMenuItemViewModel alloc] init]
  ];
  mainBarViewClass = [CUIMenuItemTextButton class];
  subitemViewClass = [CUIMenuItemIconButton class];
  entry = [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:mainBarViewClass
                                     submenuItemViewClass:subitemViewClass];
});

context(@"initialization", ^{
  it(@"should raise an exception when initialized with invalid main bar item view class", ^{
    expect(^{
      CUIDropDownMenuItemsEntry * __unused entry =
          [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:UIView.class
                                     submenuItemViewClass:mainBarViewClass];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when initialized with invalid submenu item view class", ^{
    expect(^{
      CUIDropDownMenuItemsEntry * __unused entry =
          [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:mainBarViewClass
                                     submenuItemViewClass:UIView.class];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should create a mainBarItemView with correct type", ^{
    expect(entry.mainBarItemView).to.beKindOf(mainBarViewClass);
  });

  it(@"should create a submenuView with internal stack view", ^{
    expect(entry.submenuView).toNot.beNil();
    expect([entry.submenuView wf_viewForAccessibilityIdentifier:@"StackView"]).toNot.beNil();
  });

  it(@"should create subviews with correct count and type", ^{
    UIStackView *stackView =
        (UIStackView *)[entry.submenuView wf_viewForAccessibilityIdentifier:@"StackView"];
    expect(stackView.arrangedSubviews.count).to.equal(model.subitems.count);
    for (NSUInteger i = 0; i < stackView.arrangedSubviews.count; ++i) {
      expect(stackView.arrangedSubviews[i]).to.beKindOf(subitemViewClass);
    }
  });

  it(@"should set the submenu view as a child of the mainBarItemView", ^{
    expect(entry.submenuView.superview).to.beIdenticalTo(entry.mainBarItemView);
  });

  it(@"should create nil submenuView if given nil subitems", ^{
    model.subitems = nil;
    CUIDropDownMenuItemsEntry *anotherEntry =
        [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                   mainBarItemViewClass:mainBarViewClass
                                   submenuItemViewClass:mainBarViewClass];

    expect(anotherEntry.submenuView).to.beNil();
  });
});

context(@"didTapSignal", ^{
  it(@"should send a RACTuple after the mainBarItemView is tapped", ^{
    LLSignalTestRecorder *recorder = [entry.didTapSignal testRecorder];

    UIButton *button = (UIButton *)entry.mainBarItemView;
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];

    expect(recorder).to.sendValues(@[RACTuplePack(entry, button)]);
  });

  it(@"should send a RACTuple after the items in the submenuView are tapped", ^{
    LLSignalTestRecorder *recorder = [entry.didTapSignal testRecorder];

    UIStackView *stackView =
        (UIStackView *)[entry.submenuView wf_viewForAccessibilityIdentifier:@"StackView"];
    UIButton *button0 = stackView.arrangedSubviews[0];
    [button0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    UIButton *button1 = stackView.arrangedSubviews[1];
    [button1 sendActionsForControlEvents:UIControlEventTouchUpInside];

    expect(recorder).to.sendValues(@[RACTuplePack(entry, button0), RACTuplePack(entry, button1)]);
  });

  it(@"should complete when the entry deallocated", ^{
    LLSignalTestRecorder *recorder;
    @autoreleasepool {
      CUIDropDownMenuItemsEntry *anotherEntry =
          [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:mainBarViewClass
                                     submenuItemViewClass:mainBarViewClass];
      recorder = [anotherEntry.didTapSignal testRecorder];
    }
    expect(recorder).to.complete();
  });
});

SpecEnd
