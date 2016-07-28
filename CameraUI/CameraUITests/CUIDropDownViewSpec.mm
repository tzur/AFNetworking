// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownView.h"

#import "CUIDropDownEntry.h"

@interface CUIFakeDropDownEntry : NSObject <CUIDropDownEntry>
@property (strong, nonatomic) UIView *mainBarItemView;
@property (strong, nonatomic, nullable) UIView *submenuView;
@property (strong, nonatomic, nullable) RACSignal *didTapSignal;
@end

@implementation CUIFakeDropDownEntry
- (instancetype)init {
  if (self = [super init]) {
    self.mainBarItemView = [[UIView alloc] initWithFrame:CGRectZero];
    self.submenuView = [[UIView alloc] initWithFrame:CGRectZero];
    self.didTapSignal = [RACSubject subject];
  }
  return self;
}
@end

SpecBegin(CUIDropDownView)

__block CUIDropDownView *dropDown;
__block NSArray<id<CUIDropDownEntry>> *entries;

beforeEach(^{
  entries = @[
    [[CUIFakeDropDownEntry alloc] init],
    [[CUIFakeDropDownEntry alloc] init]
  ];
  dropDown = [[CUIDropDownView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  dropDown.entries = entries;
});

context(@"initialization", ^{
  it(@"should init with empty entries", ^{
    CUIDropDownView *dropDownView = [[CUIDropDownView alloc] initWithFrame:CGRectZero];
    expect(dropDownView.entries).to.equal(@[]);
  });

  it(@"should set the hidden state of the submenuViews to YES", ^{
    expect(entries[0].submenuView.hidden).to.beTruthy();
    expect(entries[1].submenuView.hidden).to.beTruthy();
  });
});

context(@"setting entries", ^{
  it(@"should add entries to view hierarchy", ^{
    expect(dropDown.entries).to.equal(entries);
    expect(entries[0].mainBarItemView.superview).notTo.beNil();
    expect(entries[1].mainBarItemView.superview).notTo.beNil();
  });

  it(@"should use new entries", ^{
    expect(dropDown.entries).to.equal(entries);

    NSArray<id<CUIDropDownEntry>> *otherEntries = @[
      [[CUIFakeDropDownEntry alloc] init],
      [[CUIFakeDropDownEntry alloc] init],
      [[CUIFakeDropDownEntry alloc] init]
    ];
    dropDown.entries = otherEntries;
    expect(dropDown.entries).to.equal(otherEntries);

    expect(entries[0].mainBarItemView.superview).to.beNil();
    expect(entries[1].mainBarItemView.superview).to.beNil();

    expect(otherEntries[0].mainBarItemView.superview).notTo.beNil();
    expect(otherEntries[1].mainBarItemView.superview).notTo.beNil();
    expect(otherEntries[2].mainBarItemView.superview).notTo.beNil();
  });
});

it(@"should change the hidden state of a submenuView after its entry is tapped", ^{
  [(RACSubject *)entries[0].didTapSignal
      sendNext:RACTuplePack((id)entries[0], entries[0].mainBarItemView)];
  expect(entries[0].submenuView.hidden).will.beFalsy();
  expect(entries[1].submenuView.hidden).to.beTruthy();

  [(RACSubject *)entries[0].didTapSignal
      sendNext:RACTuplePack((id)entries[0], entries[0].mainBarItemView)];
  expect(entries[0].submenuView.hidden).will.beTruthy();
  expect(entries[1].submenuView.hidden).to.beTruthy();
});

it(@"should set the hidden state of a submenuView to YES after other entry is tapped", ^{
  [(RACSubject *)entries[0].didTapSignal
      sendNext:RACTuplePack((id)entries[0], entries[0].mainBarItemView)];
  expect(entries[0].submenuView.hidden).will.beFalsy();
  expect(entries[1].submenuView.hidden).to.beTruthy();

  [(RACSubject *)entries[1].didTapSignal
      sendNext:RACTuplePack((id)entries[1], entries[1].mainBarItemView)];
  expect(entries[0].submenuView.hidden).will.beTruthy();
  expect(entries[1].submenuView.hidden).will.beFalsy();
});

SpecEnd
