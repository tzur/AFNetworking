// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIDropDownView.h"

#import "CUIDropDownEntry.h"

SpecBegin(CUIDropDownView)

__block CUIDropDownView *dropDown;
__block NSArray<id<CUIDropDownEntry>> *entries;

beforeEach(^{
  entries = @[
    OCMProtocolMock(@protocol(CUIDropDownEntry)),
    OCMProtocolMock(@protocol(CUIDropDownEntry))
  ];
  OCMStub([entries[0] mainBarItemView]).andReturn([[UIView alloc] initWithFrame:CGRectZero]);
  OCMStub([entries[0] submenuView]).andReturn([[UIView alloc] initWithFrame:CGRectZero]);
  OCMStub([entries[0] didTapSignal]).andReturn([[RACSubject alloc] init]);
  OCMStub([entries[1] mainBarItemView]).andReturn([[UIView alloc] initWithFrame:CGRectZero]);
  OCMStub([entries[1] submenuView]).andReturn([[UIView alloc] initWithFrame:CGRectZero]);
  OCMStub([entries[1] didTapSignal]).andReturn([[RACSubject alloc] init]);
  dropDown = [[CUIDropDownView alloc] initWithEntries:entries];
});

context(@"initialization", ^{
  it(@"should raise an exception when initialized with nil entries", ^{
    NSArray<id<CUIDropDownEntry>> *entries = nil;
    expect(^{
      CUIDropDownView * __unused dropDown = [[CUIDropDownView alloc] initWithEntries:entries];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should set the hidden state of the submenuViews to YES", ^{
    expect(entries[0].submenuView.hidden).to.beTruthy();
    expect(entries[1].submenuView.hidden).to.beTruthy();
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
