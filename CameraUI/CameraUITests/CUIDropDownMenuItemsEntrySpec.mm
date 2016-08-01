// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownMenuItemsEntry.h"

#import "CUIMenuItemTextButton.h"
#import "CUISharedTheme.h"
#import "CUISimpleMenuItemViewModel.h"

SpecBegin(CUIDropDownMenuItemsEntry)

__block CUIDropDownMenuItemsEntry *entry;
__block CUISimpleMenuItemViewModel *model;
__block Class itemViewClass;
__block id themeMock;

beforeEach(^{
  themeMock = LTMockProtocol(@protocol(CUITheme));
  model = [[CUISimpleMenuItemViewModel alloc] init];
  model.subitems= @[
    [[CUISimpleMenuItemViewModel alloc] init],
    [[CUISimpleMenuItemViewModel alloc] init]
  ];
  itemViewClass = [CUIMenuItemTextButton class];
  entry = [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:itemViewClass
                                     submenuItemViewClass:itemViewClass];
});

context(@"initialization", ^{
  it(@"should raise an exception when initialized with nil item", ^{
    CUISimpleMenuItemViewModel *model = nil;
    expect(^{
      CUIDropDownMenuItemsEntry * __unused group =
          [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:itemViewClass
                                     submenuItemViewClass:itemViewClass];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when initialized with invalid main bar item view class", ^{
    expect(^{
      CUIDropDownMenuItemsEntry * __unused entry =
          [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:UIView.class
                                     submenuItemViewClass:itemViewClass];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise an exception when initialized with invalid submenu item view class", ^{
    expect(^{
      CUIDropDownMenuItemsEntry * __unused entry =
          [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:itemViewClass
                                     submenuItemViewClass:UIView.class];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should create a mainBarItemView that is not nil", ^{
    expect(entry.mainBarItemView).toNot.beNil();
  });
     
  it(@"should create the same subviews number as the given subitems number", ^{
    NSArray *submenuViews = ((UIStackView *)(entry.submenuView)).arrangedSubviews;
    expect([submenuViews count]).to.equal([model.subitems count]);
  });

  it(@"should set the submenu view as a child of the mainBarItemView", ^{
    expect(entry.submenuView.superview).to.beIdenticalTo(entry.mainBarItemView);
  });
  
  it(@"should create nil submenuView if given nil subitems", ^{
    model.subitems = nil;
    CUIDropDownMenuItemsEntry * entry =
        [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                   mainBarItemViewClass:itemViewClass
                                   submenuItemViewClass:itemViewClass];

    expect(entry.submenuView).to.beNil();
  });
});

context(@"didTapSignal", ^{
  it(@"should send a RACTuple after the mainBarItemView is tapped", ^{
    LLSignalTestRecorder *recorder = [entry.didTapSignal testRecorder];

    UIButton *button = (UIButton *)entry.mainBarItemView;
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];

    expect(recorder.values).to.equal(@[RACTuplePack(entry, button)]);
  });

  it(@"should send a RACTuple after the items in the submenuView are tapped", ^{
    LLSignalTestRecorder *recorder = [entry.didTapSignal testRecorder];

    UIStackView *submenuView = (UIStackView *)entry.submenuView;
    UIButton *button0 = (UIButton *)submenuView.arrangedSubviews[0];
    [button0 sendActionsForControlEvents:UIControlEventTouchUpInside];
    UIButton *button1 = (UIButton *)submenuView.arrangedSubviews[1];
    [button1 sendActionsForControlEvents:UIControlEventTouchUpInside];

    expect(recorder.values).to.equal(@[RACTuplePack(entry, button0), RACTuplePack(entry, button1)]);
  });
  
  it(@"should complete when the entry deallocated", ^{
    LLSignalTestRecorder *recorder;
    @autoreleasepool {
      CUIDropDownMenuItemsEntry * entry =
          [[CUIDropDownMenuItemsEntry alloc] initWithItem:model
                                     mainBarItemViewClass:itemViewClass
                                     submenuItemViewClass:itemViewClass];
      recorder = [entry.didTapSignal testRecorder];
    }
    expect(recorder.hasCompleted).to.beTruthy();
  });
});

SpecEnd
