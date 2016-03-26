// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangeset.h"

#import "PTNAlbum.h"
#import "PTNIncrementalChanges.h"

SpecBegin(PTNAlbumChangeset)

__block id before;
__block id after;
__block id changes;

beforeEach(^{
  before = OCMProtocolMock(@protocol(PTNAlbum));
  after = OCMProtocolMock(@protocol(PTNAlbum));
  changes = OCMClassMock([PTNIncrementalChanges class]);
});

context(@"construction", ^{
  it(@"should construct changeset with after album", ^{
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:after];

    expect(changeset.afterAlbum).to.equal(after);

    expect(changeset.beforeAlbum).to.beNil();
    expect(changeset.subalbumChanges).to.beNil();
    expect(changeset.assetChanges).to.beNil();
  });

  it(@"should construct changeset with changes", ^{
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:before
                                                                    afterAlbum:after
                                                               subalbumChanges:nil
                                                                  assetChanges:changes];

    expect(changeset.beforeAlbum).to.equal(before);
    expect(changeset.afterAlbum).to.equal(after);
    expect(changeset.subalbumChanges).to.beNil();
    expect(changeset.assetChanges).to.equal(changes);
  });
});

context(@"equality", ^{
  __block PTNAlbumChangeset *firstChangeset;
  __block PTNAlbumChangeset *secondChangeset;
  __block PTNAlbumChangeset *otherChangeset;

  beforeEach(^{
    firstChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:before
                                                      afterAlbum:after
                                                  subalbumChanges:changes
                                                    assetChanges:changes];

    secondChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:before
                                                       afterAlbum:after
                                                  subalbumChanges:changes
                                                     assetChanges:changes];

    otherChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:after];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstChangeset).to.equal(secondChangeset);
    expect(secondChangeset).to.equal(firstChangeset);

    expect(firstChangeset).notTo.equal(otherChangeset);
    expect(secondChangeset).notTo.equal(otherChangeset);
  });

  it(@"should create proper hash", ^{
    expect(firstChangeset.hash).to.equal(secondChangeset.hash);
  });
});

SpecEnd
