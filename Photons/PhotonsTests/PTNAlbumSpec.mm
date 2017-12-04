// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbum.h"

#import <LTKit/LTRandomAccessCollection.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "PTNDescriptor.h"

SpecBegin(PTNAlbum)

__block NSURL *url;
__block NSArray *subalbums;
__block NSArray *assets;
__block NSURL *nextAlbumURL;

beforeEach(^{
  url = [NSURL URLWithString:@"http://www.foo.com"];
  nextAlbumURL = [NSURL URLWithString:@"http://www.foo.com/baz"];
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
  expect(album.nextAlbumURL).to.beNil();
});

it(@"should create album with url, subalbums, assets and next album URL", ^{
  PTNAlbum *album = [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:assets
                                     nextAlbumURL:nextAlbumURL];

  expect(album.url).to.equal(url);
  expect(album.subalbums).to.equal(subalbums);
  expect(album.assets).to.equal(assets);
  expect(album.nextAlbumURL).to.equal(nextAlbumURL);
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  auto album = [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:assets
                                nextAlbumURL:nextAlbumURL];
  auto equalAlbum = [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:assets
                                     nextAlbumURL:nextAlbumURL];
  auto differentAlbums = @[
    [[PTNAlbum alloc] initWithURL:[NSURL URLWithString:@"http://baz"] subalbums:subalbums
                           assets:assets nextAlbumURL:nextAlbumURL],
    [[PTNAlbum alloc] initWithURL:url subalbums:@[] assets:assets nextAlbumURL:nextAlbumURL],
    [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:@[] nextAlbumURL:nextAlbumURL],
    [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:@[]
                     nextAlbumURL:[NSURL URLWithString:@"http://baz"]]
  ];
  return @{
    kLTEqualityExamplesObject: album,
    kLTEqualityExamplesEqualObject: equalAlbum,
    kLTEqualityExamplesDifferentObjects: differentAlbums
  };
});

SpecEnd
