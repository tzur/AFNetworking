// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetMetadata.h"

SpecBegin(PTUChangesetMetadata)

__block NSDictionary *sectionTitles;

beforeEach(^{
  sectionTitles = @{
    @0: @"bar",
    @1: @"baz"
  };
});

it(@"should correctly initialize", ^{
  PTUChangesetMetadata *metadata = [[PTUChangesetMetadata alloc] initWithTitle:@"foo"
                                                                 sectionTitles:sectionTitles];

  expect(metadata.title).to.equal(@"foo");
  expect(metadata.sectionTitles).to.equal(sectionTitles);
});

context(@"equality", ^{
  __block PTUChangesetMetadata *firstMetadata;
  __block PTUChangesetMetadata *secondMetadata;
  __block PTUChangesetMetadata *otherMetadata;

  beforeEach(^{
    firstMetadata = [[PTUChangesetMetadata alloc] initWithTitle:@"foo" sectionTitles:sectionTitles];
    secondMetadata = [[PTUChangesetMetadata alloc] initWithTitle:@"foo"
                                                   sectionTitles:sectionTitles];
    otherMetadata = [[PTUChangesetMetadata alloc] initWithTitle:nil sectionTitles:@{@3: @"baz"}];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstMetadata).to.equal(secondMetadata);
    expect(secondMetadata).to.equal(firstMetadata);

    expect(firstMetadata).notTo.equal(otherMetadata);
    expect(secondMetadata).notTo.equal(otherMetadata);
  });

  it(@"should create proper hash", ^{
    expect(firstMetadata.hash).to.equal(secondMetadata.hash);
  });
});

SpecEnd
