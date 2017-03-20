// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCompoundChangesetProvider.h"

#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"
#import "PTUTestUtils.h"

SpecBegin(PTUCompoundChangesetProvider)

__block PTUCompoundChangesetProvider *provider;
__block RACSubject *fetchChangesetA;
__block RACSubject *fetchChangesetB;
__block PTUChangesetMetadata *metadata;

beforeEach(^{
  id<PTUChangesetProvider> providerA = OCMProtocolMock(@protocol(PTUChangesetProvider));
  id<PTUChangesetProvider> providerB = OCMProtocolMock(@protocol(PTUChangesetProvider));
  fetchChangesetA = [RACSubject subject];
  fetchChangesetB = [RACSubject subject];
  OCMStub([providerA fetchChangeset]).andReturn(fetchChangesetA);
  OCMStub([providerB fetchChangeset]).andReturn(fetchChangesetB);
  metadata = [[PTUChangesetMetadata alloc] initWithTitle:@"foo" sectionTitles:@{
    @0: @"bar",
    @5: @"baz"
  }];

  provider = [[PTUCompoundChangesetProvider alloc]
              initWithChangesetProviders:@[providerA, providerB] changesetMetadata:metadata];
});

context(@"metadata", ^{
  it(@"should return given metadata for every fetchChangesetMetadata call", ^{
    expect([provider fetchChangesetMetadata]).will.sendValues(@[metadata]);
    expect([provider fetchChangesetMetadata]).will.sendValues(@[metadata]);
  });

  it(@"should complete after sending metadata", ^{
    LLSignalTestRecorder *recorder = [[provider fetchChangesetMetadata] testRecorder];

    expect(recorder).will.sendValuesWithCount(1);
    expect(recorder).to.complete();
  });
});

context(@"changeset", ^{
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    recorder = [[provider fetchChangeset] testRecorder];
  });

  it(@"start with an empty data model", ^{
    expect(recorder).will.sendValues(@[[[PTUChangeset alloc] initWithAfterDataModel:@[]]]);
  });

  it(@"send a concatinated data model on each change to the underlying data", ^{
    [fetchChangesetA sendNext:[[PTUChangeset alloc] initWithAfterDataModel:@[@[@"foo"]]]];
    [fetchChangesetB sendNext:[[PTUChangeset alloc]
        initWithAfterDataModel:@[@[@"bar"], @[@"baz"]]]];
    [fetchChangesetA sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]]
        afterDataModel:@[
          @[@"foo"],
          @[@"gaz", @"qux"]
        ] deleted:nil inserted:nil updated:nil moved:nil]];

    expect(recorder).will.sendValues(@[
      [[PTUChangeset alloc] initWithAfterDataModel:@[]],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[] afterDataModel:@[@[@"foo"]]
          deleted:nil inserted:nil updated:nil moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]]
          afterDataModel:@[@[@"foo"], @[@"bar"], @[@"baz"]] deleted:nil inserted:nil updated:nil
          moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"], @[@"bar"], @[@"baz"]]
          afterDataModel:@[
            @[@"foo"],
            @[@"gaz", @"qux"],
            @[@"bar"],
            @[@"baz"]
          ] deleted:nil inserted:nil updated:nil moved:nil],
    ]);
  });

  it(@"should send mapped insertions from the latest change", ^{
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[]
        afterDataModel:@[@[@"foo"]] deleted:nil
        inserted:@[[NSIndexPath indexPathForItem:0 inSection:0]] updated:nil moved:nil]];
    [fetchChangesetA sendNext:[[PTUChangeset alloc]
      initWithAfterDataModel:@[@[@"bar"], @[@"baz"]]]];
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]]
        afterDataModel:@[@[@"foo", @"gaz"]] deleted:nil
        inserted:@[[NSIndexPath indexPathForItem:1 inSection:0]] updated:nil moved:nil]];

    expect(recorder).will.sendValues(@[
      [[PTUChangeset alloc] initWithAfterDataModel:@[]],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[] afterDataModel:@[@[@"foo"]] deleted:nil
          inserted:@[[NSIndexPath indexPathForItem:0 inSection:0]] updated:nil moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[@"foo"]] deleted:nil inserted:nil updated:nil
          moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar"], @[@"baz"], @[@"foo"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[@"foo", @"gaz"]] deleted:nil
          inserted:@[[NSIndexPath indexPathForItem:1 inSection:2]] updated:nil moved:nil]
    ]);
  });

  it(@"should send mapped deletions from the latest change", ^{
    [fetchChangesetB sendNext:[[PTUChangeset alloc]
        initWithBeforeDataModel:@[
          @[@"foo", @"bar", @"gaz"]
        ] afterDataModel:@[@[@"foo"]] deleted:@[
         [NSIndexPath indexPathForItem:1 inSection:0],
         [NSIndexPath indexPathForItem:2 inSection:0]
        ] inserted:nil updated:nil moved:nil]];
    [fetchChangesetA sendNext:[[PTUChangeset alloc]
        initWithAfterDataModel:@[@[@"bar"], @[@"baz"]]]];
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]]
        afterDataModel:@[@[]] deleted:@[[NSIndexPath indexPathForItem:0 inSection:0]]
        inserted:nil updated:nil moved:nil]];

    expect(recorder).will.sendValues(@[
      [[PTUChangeset alloc] initWithAfterDataModel:@[]],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo", @"bar", @"gaz"]]
          afterDataModel:@[@[@"foo"]] deleted:@[
           [NSIndexPath indexPathForItem:1 inSection:0],
           [NSIndexPath indexPathForItem:2 inSection:0]
          ] inserted:nil updated:nil moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[@"foo"]] deleted:nil inserted:nil updated:nil
          moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar"], @[@"baz"], @[@"foo"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[]] deleted:@[
            [NSIndexPath indexPathForItem:0 inSection:2]
          ] inserted:nil updated:nil moved:nil]
    ]);
  });

  it(@"should send mapped updates from the latest change", ^{
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]]
        afterDataModel:@[@[@"bar"]] deleted:nil inserted:nil
        updated:@[[NSIndexPath indexPathForItem:0 inSection:0]] moved:nil]];
    [fetchChangesetA sendNext:[[PTUChangeset alloc]
        initWithAfterDataModel:@[@[@"bar"], @[@"baz"]]]];
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar"]]
        afterDataModel:@[@[@"gaz"]] deleted:nil inserted:nil
        updated:@[[NSIndexPath indexPathForItem:0 inSection:0]] moved:nil]];

    expect(recorder).will.sendValues(@[
      [[PTUChangeset alloc] initWithAfterDataModel:@[]],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo"]] afterDataModel:@[@[@"bar"]]
          deleted:nil inserted:nil updated:@[[NSIndexPath indexPathForItem:0 inSection:0]]
          moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[@"bar"]] deleted:nil inserted:nil updated:nil
          moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar"], @[@"baz"], @[@"bar"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[@"gaz"]] deleted:nil
          inserted:nil updated:@[[NSIndexPath indexPathForItem:0 inSection:2]] moved:nil]
    ]);
  });

  it(@"should send mapped moves from the latest change", ^{
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo", @"bar"]]
        afterDataModel:@[@[@"bar", @"foo"]] deleted:nil inserted:nil updated:nil
        moved:@[PTUCreateChangesetMove(0, 1, 0)]]];
    [fetchChangesetA sendNext:[[PTUChangeset alloc]
        initWithAfterDataModel:@[@[@"bar"], @[@"baz"]]]];
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar", @"foo"]]
        afterDataModel:@[@[@"foo", @"bar"]] deleted:nil inserted:nil updated:nil
        moved:@[PTUCreateChangesetMove(0, 1, 0)]]];

    expect(recorder).will.sendValues(@[
      [[PTUChangeset alloc] initWithAfterDataModel:@[]],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo", @"bar"]]
          afterDataModel:@[@[@"bar", @"foo"]] deleted:nil inserted:nil updated:nil
          moved:@[PTUCreateChangesetMove(0, 1, 0)]],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar", @"foo"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[@"bar", @"foo"]] deleted:nil inserted:nil
          updated:nil moved:nil],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"bar"], @[@"baz"], @[@"bar", @"foo"]]
          afterDataModel:@[@[@"bar"], @[@"baz"], @[@"foo", @"bar"]] deleted:nil inserted:nil
          updated:nil moved:@[PTUCreateChangesetMove(0, 1, 2)]]
    ]);
  });

  it(@"should send mapped incremental changes from the latest change", ^{
    [fetchChangesetB sendNext:[[PTUChangeset alloc] initWithBeforeDataModel:@[
      @[@"foo", @"bar", @"baz", @"gaz", @"qux"]
    ] afterDataModel:@[@[@"foofoo", @"qux", @"baz", @"gaz", @"zebra"]]
        deleted:@[[NSIndexPath indexPathForItem:1 inSection:0]]
        inserted:@[[NSIndexPath indexPathForItem:4 inSection:0]]
        updated:@[[NSIndexPath indexPathForItem:0 inSection:0]]
        moved:@[PTUCreateChangesetMove(4, 1, 0)]]];
    [fetchChangesetA sendNext:[[PTUChangeset alloc] initWithAfterDataModel:@[
      @[@"bar"],
      @[@"baz"]
    ]]];
    [fetchChangesetB sendNext:[[PTUChangeset alloc]
        initWithBeforeDataModel:@[@[@"foofoo", @"qux", @"baz", @"gaz", @"zebra"]]
        afterDataModel:@[@[@"foo", @"bar", @"baz", @"gaz", @"qux"]]
        deleted:@[[NSIndexPath indexPathForItem:3 inSection:0]]
        inserted:@[[NSIndexPath indexPathForItem:1 inSection:0]]
        updated:@[[NSIndexPath indexPathForItem:0 inSection:0]]
        moved:@[PTUCreateChangesetMove(1, 4, 0)]]];

    expect(recorder).will.sendValues(@[
      [[PTUChangeset alloc] initWithAfterDataModel:@[]],
      [[PTUChangeset alloc] initWithBeforeDataModel:@[@[@"foo", @"bar", @"baz", @"gaz", @"qux"]]
          afterDataModel:@[@[@"foofoo", @"qux", @"baz", @"gaz", @"zebra"]]
          deleted:@[[NSIndexPath indexPathForItem:1 inSection:0]]
          inserted:@[[NSIndexPath indexPathForItem:4 inSection:0]]
          updated:@[[NSIndexPath indexPathForItem:0 inSection:0]]
          moved:@[PTUCreateChangesetMove(4, 1, 0)]],
      [[PTUChangeset alloc]
          initWithBeforeDataModel:@[@[@"foofoo", @"qux", @"baz", @"gaz", @"zebra"]]
          afterDataModel:@[
            @[@"bar"],
            @[@"baz"],
            @[@"foofoo", @"qux", @"baz", @"gaz", @"zebra"]
          ] deleted:nil inserted:nil updated:nil moved:nil],
      [[PTUChangeset alloc]
          initWithBeforeDataModel:@[
            @[@"bar"],
            @[@"baz"],
            @[@"foofoo", @"qux", @"baz", @"gaz", @"zebra"]
          ] afterDataModel:@[
            @[@"bar"],
            @[@"baz"],
            @[@"foo", @"bar", @"baz", @"gaz", @"qux"]
          ] deleted:@[[NSIndexPath indexPathForItem:3 inSection:2]]
          inserted:@[[NSIndexPath indexPathForItem:1 inSection:2]]
          updated:@[[NSIndexPath indexPathForItem:0 inSection:2]]
          moved:@[PTUCreateChangesetMove(1, 4, 2)]]
    ]);
  });

  it(@"should complete when all underlying changeset providers complete", ^{
    [fetchChangesetA sendCompleted];
    expect(recorder).notTo.complete();
    [fetchChangesetB sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should err when any of the underlying changeset providers err", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [fetchChangesetA sendError:error];
    expect(recorder).to.sendError(error);
  });
});

SpecEnd
