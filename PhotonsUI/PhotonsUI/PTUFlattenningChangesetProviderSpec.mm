// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUFlattenningChangesetProvider.h"

#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"
#import "PTUChangesetMove.h"
#import "PTUTestUtils.h"

SpecBegin(PTUFlattenningChangesetProvider)

__block id<PTUChangesetProvider> provider;
__block PTUFlattenningChangesetProvider *flattenningProvider;
__block RACSubject *dataChanges;
__block RACSubject *metadataChanges;

beforeEach(^{
  dataChanges = [RACSubject subject];
  metadataChanges = [RACSubject subject];
  provider = OCMProtocolMock(@protocol(PTUChangesetProvider));
  OCMStub([provider fetchChangeset]).andReturn(dataChanges);
  OCMStub([provider fetchChangesetMetadata]).andReturn(metadataChanges);
  flattenningProvider = [[PTUFlattenningChangesetProvider alloc]
                         initWithChangesetProvider:provider];
});

it(@"should not alter changeset metadata", ^{
  expect([flattenningProvider fetchChangesetMetadata]).to.equal(metadataChanges);
});

context(@"changeset", ^{
  __block LLSignalTestRecorder *fetchChangeset;

  beforeEach(^{
    fetchChangeset = [[flattenningProvider fetchChangeset] testRecorder];
  });

  it(@"should flatten sections", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1, @2], @[@3, @4]]];
    [dataChanges sendNext:changeset];

    PTUChangeset *flattenedChangeset =
        [[PTUChangeset alloc] initWithAfterDataModel:@[@[@1, @2, @3, @4]]];
    expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, flattenedChangeset);
    });
  });

  it(@"should ignore empty sections", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[@[], @[@3, @4]]];
    [dataChanges sendNext:changeset];

    PTUChangeset *flattenedChangeset =
        [[PTUChangeset alloc] initWithAfterDataModel:@[@[@3, @4]]];
    expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, flattenedChangeset);
    });
  });

  it(@"should not alter empty changesets", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithAfterDataModel:@[]];
    [dataChanges sendNext:changeset];

    expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, changeset);
    });
  });

  it(@"should flatten sections in both before and after data models", ^{
    PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2], @[@3, @4]]
                                                             afterDataModel:@[@[@5, @6], @[@7, @8]]
                                                                    deleted:nil inserted:nil
                                                                    updated:nil moved:nil];
    [dataChanges sendNext:changeset];

    PTUChangeset *flattenedChangeset =
        [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                       afterDataModel:@[@[@5, @6, @7, @8]]
                                              deleted:nil inserted:nil
                                              updated:nil moved:nil];
    expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
      return PTUChangesetSemanticallyEqual(sentChangeset, flattenedChangeset);
    });
  });

  context(@"updates", ^{
    it(@"should correctly map deletions of flattened sections", ^{
      NSArray *deletions = @[
        [NSIndexPath indexPathForItem:1 inSection:0],
        [NSIndexPath indexPathForItem:0 inSection:1]
      ];

      PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[
        @[@1, @2],
        @[@3, @4]
      ] afterDataModel:@[@[@1], @[@2]] deleted:deletions inserted:nil updated:nil moved:nil];
      [dataChanges sendNext:changeset];

      NSArray *flattenedDeletions = @[
        [NSIndexPath indexPathForItem:1 inSection:0],
        [NSIndexPath indexPathForItem:2 inSection:0]
      ];
      PTUChangeset *flattened = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                                               afterDataModel:@[@[@1, @2]]
                                                                      deleted:flattenedDeletions
                                                                    inserted:nil updated:nil
                                                                       moved:nil];

      expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
        return PTUChangesetSemanticallyEqual(sentChangeset, flattened);
      });
    });

    it(@"should correctly map insertions of flattened sections", ^{
      NSArray *insertions = @[
        [NSIndexPath indexPathForItem:0 inSection:1],
        [NSIndexPath indexPathForItem:1 inSection:0]
      ];

      PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2], @[@3]]
          afterDataModel:@[@[@1, @5, @2], @[@4, @3]] deleted:nil inserted:insertions updated:nil
          moved:nil];
      [dataChanges sendNext:changeset];

      NSArray *mappedInsertions = @[
        [NSIndexPath indexPathForItem:2 inSection:0],
        [NSIndexPath indexPathForItem:1 inSection:0]
      ];
      PTUChangeset *flattened = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3]]
          afterDataModel:@[@[@1, @5, @2, @4, @3]] deleted:nil inserted:mappedInsertions updated:nil
          moved:nil];

      expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
        return PTUChangesetSemanticallyEqual(sentChangeset, flattened);
      });
    });

    it(@"should correctly map updates of flattened sections", ^{
      NSArray *updates = @[
        [NSIndexPath indexPathForItem:0 inSection:1],
        [NSIndexPath indexPathForItem:2 inSection:1]
      ];

      PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[
        @[@1],
        @[@2, @3, @4]
      ] afterDataModel:@[
        @[@1],
        @[@5, @3, @6]
      ] deleted:nil inserted:nil updated:updates moved:nil];
      [dataChanges sendNext:changeset];

      NSArray *mappedUpdates = @[
        [NSIndexPath indexPathForItem:1 inSection:0],
        [NSIndexPath indexPathForItem:3 inSection:0]
      ];
      PTUChangeset *flattened = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                                               afterDataModel:@[@[@1, @5, @3, @6]]
                                                                      deleted:nil inserted:nil
                                                                      updated:mappedUpdates
                                                                        moved:nil];

      expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
        return PTUChangesetSemanticallyEqual(sentChangeset, flattened);
      });
    });

    it(@"should correctly map moves of flattened sections", ^{
      NSArray *moves = @[
        [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:0 inSection:1]
                                         to:[NSIndexPath indexPathForItem:2 inSection:0]]
      ];

      PTUChangeset *changeset = [[PTUChangeset alloc] initWithBeforeDataModel:@[
        @[@1, @2, @3],
        @[@4]
      ] afterDataModel:@[@[@1, @2, @4, @3]] deleted:nil inserted:nil updated:nil moved:moves];
      [dataChanges sendNext:changeset];

      NSArray *mappedMoves = @[
        [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:3 inSection:0]
                                         to:[NSIndexPath indexPathForItem:2 inSection:0]]
      ];
      PTUChangeset *flattened = [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                                               afterDataModel:@[@[@1, @2, @4, @3]]
                                                                      deleted:nil inserted:nil
                                                                      updated:nil
                                                                        moved:mappedMoves];

      expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
        return PTUChangesetSemanticallyEqual(sentChangeset, flattened);
      });
    });

    it(@"should correctly map multiple simultaneous changes", ^{
      NSArray *deletions = @[
        [NSIndexPath indexPathForItem:1 inSection:1]
      ];
      NSArray *insertions = @[
        [NSIndexPath indexPathForItem:0 inSection:0],
        [NSIndexPath indexPathForItem:1 inSection:1],
        [NSIndexPath indexPathForItem:2 inSection:1]
      ];
      NSArray *updates = @[
        [NSIndexPath indexPathForItem:1 inSection:1]
      ];
      NSArray *moves = @[
        [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:0 inSection:0]
                                         to:[NSIndexPath indexPathForItem:0 inSection:1]]
      ];

      PTUChangeset *changeset =
          [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2], @[@3, @4]]
                                         afterDataModel:@[@[@0, @2], @[@1, @33, @5, @6]]
                                                deleted:deletions inserted:insertions
                                                updated:updates moved:moves];
      [dataChanges sendNext:changeset];

      NSArray *mappedDeletions = @[
        [NSIndexPath indexPathForItem:3 inSection:0]
      ];
      NSArray *mappedInsertions = @[
        [NSIndexPath indexPathForItem:0 inSection:0],
        [NSIndexPath indexPathForItem:3 inSection:0],
        [NSIndexPath indexPathForItem:4 inSection:0]
      ];
      NSArray *mappedUpdates = @[
        [NSIndexPath indexPathForItem:3 inSection:0]
      ];
      NSArray *mappedMoves = @[
        [PTUChangesetMove changesetMoveFrom:[NSIndexPath indexPathForItem:0 inSection:0]
                                         to:[NSIndexPath indexPathForItem:2 inSection:0]]
      ];

      PTUChangeset *flattened =
          [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@1, @2, @3, @4]]
                                         afterDataModel:@[@[@0, @2, @1, @33, @5, @6]]
                                                deleted:mappedDeletions inserted:mappedInsertions
                                                updated:mappedUpdates moved:mappedMoves];

      expect(fetchChangeset).will.matchValue(0, ^BOOL(PTUChangeset *sentChangeset) {
        return PTUChangesetSemanticallyEqual(sentChangeset, flattened);
      });
    });

    it(@"should complete when underlying changeset provider complete", ^{
      [dataChanges sendCompleted];
      expect(fetchChangeset).to.complete();
    });

    it(@"should err when underlying changeset provider err", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      [dataChanges sendError:error];
      expect(fetchChangeset).to.sendError(error);
    });
  });
});

SpecEnd
