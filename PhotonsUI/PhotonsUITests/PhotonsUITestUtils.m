// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PhotonsUITestUtils.h"

#import <Photons/PTNAlbum.h>

#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

PTUChangesetMove *PTUCreateChangesetMove(NSUInteger from, NSUInteger to, NSUInteger section) {
  NSIndexPath *fromPath = [NSIndexPath indexPathForItem:from inSection:section];
  NSIndexPath *toPath = [NSIndexPath indexPathForItem:to inSection:section];
  return [PTUChangesetMove changesetMoveFrom:fromPath to:toPath];
}

id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<PTNCollection> _Nullable assets,
                            id<PTNCollection> _Nullable subalbums) {
  id<PTNAlbum> album = OCMProtocolMock(@protocol(PTNAlbum));
  OCMStub([album url]).andReturn(url);
  OCMStub([album assets]).andReturn(assets);
  OCMStub([album subalbums]).andReturn(subalbums);
  return album;
}

NS_ASSUME_NONNULL_END
