// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "MPMediaItem+Photons.h"

#import "NSURL+MediaLibrary.h"

SpecBegin(MPMediaItem_Photons)

__block MPMediaItem *item;

beforeEach(^{
  item = OCMClassMock([MPMediaItem class]);
});

it(@"should return Photons identifier url", ^{
  OCMStub([item persistentID]).andReturn(321);
  auto url = [NSURL ptn_mediaLibraryAssetWithItem:item];

  MPMediaItem *itemPartialMock = OCMPartialMock([[MPMediaItem alloc] init]);
  OCMStub(itemPartialMock.persistentID).andReturn(321);

  expect(itemPartialMock.ptn_identifier).to.equal(url);
});

it(@"should return localized title as the title of the item", ^{
  MPMediaItem *item = OCMPartialMock([[MPMediaItem alloc] init]);
  OCMStub(item.title).andReturn(@"foo");

  expect(item.localizedTitle).to.equal(@"foo");
});

it(@"should return nil filename", ^{
  MPMediaItem *item = OCMPartialMock([[MPMediaItem alloc] init]);
  OCMStub(item.title).andReturn(@"foo");

  expect(item.filename).to.beNil();
});

it(@"should return video trait descriptor", ^{
  auto item = [[MPMediaItem alloc] init];
  expect(item.descriptorTraits).to.equal([NSSet setWithObject:kPTNDescriptorTraitAudiovisualKey]);
});

it(@"should return video and cloud trait descriptors for cloud items", ^{
  MPMediaItem *item = OCMPartialMock([[MPMediaItem alloc] init]);
  OCMStub([item isCloudItem]).andReturn(YES);
  expect(item.descriptorTraits).to.equal([NSSet setWithObjects:kPTNDescriptorTraitAudiovisualKey,
                                          kPTNDescriptorTraitCloudBasedKey, nil]);
});

it(@"should return descriptor capabilities none", ^{
  expect([[MPMediaItem alloc] init].descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
});

it(@"should return creation date", ^{
  auto date = [NSDate date];
  MPMediaItem *item = OCMPartialMock([[MPMediaItem alloc] init]);
  OCMStub(item.creationDate).andReturn(date);

  expect(item.creationDate).to.equal(date);
});

it(@"should return nil modification date", ^{
  expect([[MPMediaItem alloc] init].modificationDate).to.beNil();
});

it(@"should return duration", ^{
  MPMediaItem *item = OCMPartialMock([[MPMediaItem alloc] init]);
  OCMStub(item.playbackDuration).andReturn(1.25);

  expect(item.duration).to.equal(1.25);
});

it(@"should return asset descriptor capabilities none", ^{
  expect([[MPMediaItem alloc] init].assetDescriptorCapabilities)
      .to.equal(PTNAssetDescriptorCapabilityNone);
});

SpecEnd
