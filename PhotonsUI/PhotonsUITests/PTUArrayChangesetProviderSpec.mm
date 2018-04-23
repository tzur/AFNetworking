// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTUArrayChangesetProvider.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTNTestUtils.h"
#import "PTUChangeset.h"
#import "PTUChangesetMetadata.h"

static NSString * const kChangesetTitle = @"foo";

SpecBegin(PTUArrayChangesetProvider)

__block PTUArrayChangesetProvider *provider;
__block NSArray<id<PTNDescriptor>> *descriptors;

beforeEach(^{
  descriptors = @[PTNCreateDescriptor(nil, nil, 0, nil)];
  provider = [[PTUArrayChangesetProvider alloc] initWithDescriptors:descriptors
                                                     changesetTitle:kChangesetTitle];
});

context(@"fetchChangeset", ^{
  it(@"should return a signal that sends the descriptors and completes", ^{
    LLSignalTestRecorder *recorder = [[provider fetchChangeset] testRecorder];

    expect(recorder).to.sendValues(@[[[PTUChangeset alloc] initWithAfterDataModel:@[descriptors]]]);
    expect(recorder).to.complete();
  });
});

context(@"fetchChangesetMetadata", ^{
  it(@"should return a signal that sends metadata with the changeset title and completes", ^{
    LLSignalTestRecorder *recorder = [[provider fetchChangesetMetadata] testRecorder];

    PTUChangesetMetadata *metadate = [[PTUChangesetMetadata alloc] initWithTitle:kChangesetTitle
                                                                   sectionTitles:@{}];
    expect(recorder).to.sendValues(@[metadate]);
    expect(recorder).to.complete();
  });
});

SpecEnd
