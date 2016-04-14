// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNTestUtils.h"

#import "PTNAlbum.h"

NS_ASSUME_NONNULL_BEGIN

id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<PTNCollection> _Nullable assets,
                            id<PTNCollection> _Nullable subalbums) {
  id<PTNAlbum> album = OCMProtocolMock(@protocol(PTNAlbum));
  OCMStub([album url]).andReturn(url);
  OCMStub([album assets]).andReturn(assets);
  OCMStub([album subalbums]).andReturn(subalbums);
  return album;
}

NS_ASSUME_NONNULL_END
