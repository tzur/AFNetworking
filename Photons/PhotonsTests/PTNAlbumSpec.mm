// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbum.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTNDescriptor.h"

SpecBegin(PTNAlbum)

__block NSURL *url;
__block NSArray *subalbums;
__block NSArray *assets;

beforeEach(^{
  url = [NSURL URLWithString:@"http://www.foo.com"];
  subalbums = @[
    OCMProtocolMock(@protocol(PTNAlbumDescriptor)),
    OCMProtocolMock(@protocol(PTNAlbumDescriptor))
  ];
  assets = @[
    OCMProtocolMock(@protocol(PTNAssetDescriptor)),
    OCMProtocolMock(@protocol(PTNAssetDescriptor))
  ];
});

it(@"should create album with url, subalbums and assets", ^{
  PTNAlbum *album = [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:assets];

  expect(album.url).to.equal(url);
  expect(album.subalbums).to.equal(subalbums);
  expect(album.assets).to.equal(assets);
});

context(@"equality", ^{
  __block PTNAlbum *firstAlbum;
  __block PTNAlbum *secondAlbum;

  beforeEach(^{
    firstAlbum = [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:assets];
    secondAlbum = [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:assets];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstAlbum).to.equal(secondAlbum);
    expect(secondAlbum).to.equal(firstAlbum);
  });

  it(@"should create proper hash", ^{
    expect(firstAlbum.hash).to.equal(secondAlbum.hash);
  });
});

SpecEnd
