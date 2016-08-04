// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetProviderReverser.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetMove.h"
#import "PTUTestUtils.h"

SpecBegin(PTUChangesetProviderReverser)

__block id<PTUChangesetProvider> provider;
__block PTUChangesetProviderReverser *reversedProvider;
__block RACSubject *dataChanges;
__block RACSubject *metadataChanges;

beforeEach(^{
  dataChanges = [RACSubject subject];
  metadataChanges = [RACSubject subject];
  provider = OCMProtocolMock(@protocol(PTUChangesetProvider));
  OCMStub([provider fetchChangeset]).andReturn(dataChanges);
  OCMStub([provider fetchChangesetMetadata]).andReturn(metadataChanges);
  reversedProvider = [[PTUChangesetProviderReverser alloc] initWithProvider:provider
      sectionsToReverse:[NSIndexSet indexSetWithIndex:0]];
});

it(@"should not change metadata", ^{
  LLSignalTestRecorder *values = [[reversedProvider fetchChangesetMetadata] testRecorder];

  PTUChangesetMetadata *metadata = [[PTUChangesetMetadata alloc] initWithTitle:@"foo"
                                                                sectionTitles:@{
    @0: @"bar",
    @3: @"baz"
  }];

  [metadataChanges sendNext:metadata];
  expect(values).will.sendValues(@[metadata]);
});

it(@"should only reverse to-reverse sections", ^{
  LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1, @2], @[@3, @4]]];
  [dataChanges sendNext:changeset];

  PTUChangeset *reveresedChangeset =
      [[PTUChangeset alloc] initWithAfterDataModel:@[@[@2, @1], @[@3, @4]]];
  expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
    return PTUChangesetSemanticallyEqual(sentChangeset, reveresedChangeset);
  });
});

it(@"should reverse all sections when no to-reverse indexes are given", ^{
  PTUChangesetProviderReverser *globalReversedProvider =
      [[PTUChangesetProviderReverser alloc] initWithProvider:provider];

  LLSignalTestRecorder *values = [[globalReversedProvider fetchChangeset] testRecorder];

  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1, @2], @[@3, @4]]];
  [dataChanges sendNext:changeset];

  PTUChangeset *reveresedChangeset =
      [[PTUChangeset alloc] initWithAfterDataModel:@[@[@2, @1], @[@4, @3]]];
  expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
    return PTUChangesetSemanticallyEqual(sentChangeset, reveresedChangeset);
  });
});

it(@"should correctly handle empty sections", ^{
  LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

  PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[], @[@3, @4]]];
  [dataChanges sendNext:changeset];

  expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
    return PTUChangesetSemanticallyEqual(sentChangeset, changeset);
  });
});

it(@"should reverse to-reverse sections in both before and after data models", ^{
  LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

  PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2], @[@3, @4]]
                                                           afterDataModel:@[@[@5, @6], @[@7, @8]]
                                                                  deleted:nil inserted:nil
                                                                  updated:nil moved:nil];
  [dataChanges sendNext:changeset];

  PTUChangeset *reveresedChangeset =
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@2, @1], @[@3, @4]]
                                     afterDataModel:@[@[@6, @5], @[@7, @8]]
                                            deleted:nil inserted:nil
                                            updated:nil moved:nil];
  expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
    return PTUChangesetSemanticallyEqual(sentChangeset, reveresedChangeset);
  });
});

context(@"updates", ^{
  it(@"should not alter changes of non-reversed sections", ^{
    LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

    NSArray *deleted = @[[NSIndexPath indexPathForItem:1 inSection:1]];
    NSArray *inserted = @[[NSIndexPath indexPathForItem:1 inSection:1]];
    NSArray *updated = @[[NSIndexPath indexPathForItem:1 inSection:1]];
    NSArray *moved = @[
      [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:0 inSection:1]
                                       to:[NSIndexPath indexPathForItem:1 inSection:1]]
    ];

    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[], @[@3, @4]]
                                                             afterDataModel:@[@[], @[@7, @8]]
                                                                    deleted:deleted
                                                                   inserted:inserted
                                                                    updated:updated moved:moved];
    [dataChanges sendNext:changeset];

    expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, changeset);
    });
  });

  it(@"should correctly reverse deletions of reversed sections", ^{
    LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

    NSArray *deletions = @[
      [NSIndexPath indexPathForItem:2 inSection:0],
      [NSIndexPath indexPathForItem:3 inSection:0]
    ];

    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                                             afterDataModel:@[@[@1, @2]]
                                                                    deleted:deletions inserted:nil
                                                                    updated:nil moved:nil];
    [dataChanges sendNext:changeset];

    NSArray *reversedDeletions = @[
      [NSIndexPath indexPathForItem:1 inSection:0],
      [NSIndexPath indexPathForItem:0 inSection:0]
    ];
    PTUChangeset *reversed = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@4, @3, @2, @1]]
                                                             afterDataModel:@[@[@2, @1]]
                                                                    deleted:reversedDeletions
                                                                  inserted:nil updated:nil
                                                                     moved:nil];

    expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, reversed);
    });
  });

  it(@"should correctly reverse insertions of reversed sections", ^{
    LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

    NSArray *insertions = @[
      [NSIndexPath indexPathForItem:1 inSection:0],
      [NSIndexPath indexPathForItem:3 inSection:0]
    ];

    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3]]
                                                             afterDataModel:@[@[@1, @5, @2, @4, @3]]
                                                                    deleted:nil inserted:insertions
                                                                    updated:nil moved:nil];
    [dataChanges sendNext:changeset];


    NSArray *reversedInsertions = @[
      [NSIndexPath indexPathForItem:3 inSection:0],
      [NSIndexPath indexPathForItem:1 inSection:0]
    ];
    PTUChangeset *reversed = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@3, @2, @1]]
                                                            afterDataModel:@[@[@3, @4, @2, @5, @1]]
                                                                   deleted:nil
                                                                  inserted:reversedInsertions
                                                                   updated:nil moved:nil];

    expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, reversed);
    });
  });

  it(@"should correctly reverse insertions of reversed sections outside original bounds", ^{
    LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

    NSArray *insertions = @[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:4 inSection:0],
      [NSIndexPath indexPathForItem:5 inSection:0],
      [NSIndexPath indexPathForItem:6 inSection:0]
    ];

    PTUChangeset *changeset =
        [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3]]
                                       afterDataModel:@[@[@0, @1, @2, @3, @4, @5, @6]]
                                              deleted:nil inserted:insertions updated:nil
                                                moved:nil];
    [dataChanges sendNext:changeset];


    NSArray *reversedInsertions = @[
      [NSIndexPath indexPathForItem:6 inSection:0],
      [NSIndexPath indexPathForItem:2 inSection:0],
      [NSIndexPath indexPathForItem:1 inSection:0],
      [NSIndexPath indexPathForItem:0 inSection:0]
    ];
    PTUChangeset *reversed =
        [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@3, @2, @1]]
                                       afterDataModel:@[@[@6, @5, @4, @3, @2, @1, @0]]
                                              deleted:nil inserted:reversedInsertions updated:nil
                                                moved:nil];

    expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, reversed);
    });
  });

  it(@"should correctly reverse updates of reversed sections", ^{
    LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

    NSArray *updates = @[
      [NSIndexPath indexPathForItem:1 inSection:0],
      [NSIndexPath indexPathForItem:3 inSection:0]
    ];

    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                                             afterDataModel:@[@[@1, @5, @3, @6]]
                                                                    deleted:nil inserted:nil
                                                                    updated:updates moved:nil];
    [dataChanges sendNext:changeset];


    NSArray *reversedUpdates = @[
      [NSIndexPath indexPathForItem:2 inSection:0],
      [NSIndexPath indexPathForItem:0 inSection:0]
    ];
    PTUChangeset *reversed = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@4, @3, @2, @1]]
                                                            afterDataModel:@[@[@6, @3, @5, @1]]
                                                                   deleted:nil inserted:nil
                                                                   updated:reversedUpdates
                                                                     moved:nil];

    expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, reversed);
    });
  });

  it(@"should correctly reverse moves of reversed sections", ^{
    LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

    NSArray *moves = @[
      [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:1 inSection:0]
                                       to:[NSIndexPath indexPathForItem:3 inSection:0]]
    ];

    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                                             afterDataModel:@[@[@1, @3, @4, @2]]
                                                                    deleted:nil inserted:nil
                                                                    updated:nil moved:moves];
    [dataChanges sendNext:changeset];


    NSArray *reversedMoves = @[
      [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:2 inSection:0]
                                       to:[NSIndexPath indexPathForItem:0 inSection:0]]
    ];
    PTUChangeset *reversed = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@4, @3, @2, @1]]
                                                            afterDataModel:@[@[@2, @4, @3, @1]]
                                                                   deleted:nil inserted:nil
                                                                   updated:nil
                                                                     moved:reversedMoves];

    expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, reversed);
    });
  });

  it(@"should correctly reverse multiple simultanous changes", ^{
    LLSignalTestRecorder *values = [[reversedProvider fetchChangeset] testRecorder];

    NSArray *deletions = @[
      [NSIndexPath indexPathForItem:3 inSection:0]
    ];
    NSArray *insertions = @[
      [NSIndexPath indexPathForItem:0 inSection:0],
      [NSIndexPath indexPathForItem:4 inSection:0],
      [NSIndexPath indexPathForItem:5 inSection:0]
    ];
    NSArray *updates = @[
      [NSIndexPath indexPathForItem:3 inSection:0]
    ];
    NSArray *moves = @[
      [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:1 inSection:0]
                                       to:[NSIndexPath indexPathForItem:1 inSection:0]]
    ];

    PTUChangeset *changeset =
        [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                       afterDataModel:@[@[@0, @2, @1, @33, @5, @6]]
                                              deleted:deletions inserted:insertions
                                              updated:updates moved:moves];
    [dataChanges sendNext:changeset];


    NSArray *reversedDeletions = @[
      [NSIndexPath indexPathForItem:0 inSection:0]
    ];
    NSArray *reversedInsertions = @[
      [NSIndexPath indexPathForItem:5 inSection:0],
      [NSIndexPath indexPathForItem:1 inSection:0],
      [NSIndexPath indexPathForItem:0 inSection:0]
    ];
    NSArray *reversedUpdates = @[
      [NSIndexPath indexPathForItem:2 inSection:0]
    ];
    NSArray *reversedMoves = @[
      [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:2 inSection:0]
                                       to:[NSIndexPath indexPathForItem:4 inSection:0]]
    ];

    PTUChangeset *reversed =
        [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@4, @3, @2, @1]]
                                       afterDataModel:@[@[@6, @5, @33, @1, @2, @0]]
                                              deleted:reversedDeletions inserted:reversedInsertions
                                              updated:reversedUpdates moved:reversedMoves];

    expect(values).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, reversed);
    });
  });
});

SpecEnd
