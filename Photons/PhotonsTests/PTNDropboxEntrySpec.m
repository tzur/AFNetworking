// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxEntry.h"

SpecBegin(PTNDropboxFileIdentifier)

static NSString * const kPath = @"/foo/bar";
static NSString * const kRevision = @"baz";

it(@"should initialize with path and revision", ^{
  PTNDropboxEntry *identifier = [PTNDropboxEntry entryWithPath:kPath andRevision:kRevision];

  expect(identifier.path).to.equal(kPath);
  expect(identifier.revision).to.equal(kRevision);
});

it(@"should initialize with path", ^{
  PTNDropboxEntry *identifier = [PTNDropboxEntry entryWithPath:kPath];

  expect(identifier.path).to.equal(kPath);
  expect(identifier.revision).to.beNil();
});

context(@"equality", ^{
  __block PTNDropboxEntry *firstIdentifier;
  __block PTNDropboxEntry *secondIdentifier;
  __block PTNDropboxEntry *otherIdentifier;

  context(@"revision", ^{
    beforeEach(^{
      firstIdentifier = [PTNDropboxEntry entryWithPath:kPath andRevision:kRevision];
      secondIdentifier = [PTNDropboxEntry entryWithPath:kPath andRevision:kRevision];
      otherIdentifier = [PTNDropboxEntry entryWithPath:@"/bar/baz" andRevision:@"qux"];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstIdentifier).to.equal(secondIdentifier);
      expect(secondIdentifier).to.equal(firstIdentifier);
    });

    it(@"should create proper hash", ^{
      expect(firstIdentifier.hash).to.equal(secondIdentifier.hash);
    });
  });

  context(@"no revision", ^{
    beforeEach(^{
      firstIdentifier = [PTNDropboxEntry entryWithPath:kPath];
      secondIdentifier = [PTNDropboxEntry entryWithPath:kPath];
      otherIdentifier = [PTNDropboxEntry entryWithPath:@"/bar/baz"];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstIdentifier).to.equal(secondIdentifier);
      expect(secondIdentifier).to.equal(firstIdentifier);
    });

    it(@"should create proper hash", ^{
      expect(firstIdentifier.hash).to.equal(secondIdentifier.hash);
    });
  });
});

SpecEnd
