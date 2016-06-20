// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNInterceptingAssetManager.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTRandomAccessCollection.h>

#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNFakeAssetManager.h"
#import "PTNImageFetchOptions.h"
#import "PTNIncrementalChanges.h"
#import "PTNProgress.h"
#import "PTNResizingStrategy.h"
#import "PTNTestUtils.h"

static BOOL PTNCollectionSemanticallyEqual(id<LTRandomAccessCollection> lhs,
                                    id<LTRandomAccessCollection> rhs) {
  if (lhs == rhs) {
    return YES;
  }

  if (lhs.count != rhs.count) {
    return NO;
  }

  for (NSUInteger i = 0; i < lhs.count; ++i) {
    if (![lhs[i] isEqual:rhs[i]]) {
      return NO;
    }
  }

  return YES;
}

static BOOL PTNAlbumSemanticallyEqual(id<PTNAlbum> lhs, id<PTNAlbum> rhs) {
  return lhs == rhs ||
      ([lhs.url isEqual:rhs.url] &&
      PTNCollectionSemanticallyEqual(lhs.subalbums, rhs.subalbums) &&
      PTNCollectionSemanticallyEqual(lhs.assets, rhs.assets));
}

static BOOL PTNChangesetSemanticallyEqual(PTNAlbumChangeset *lhs, PTNAlbumChangeset *rhs) {
  return lhs == rhs ||
      ((lhs.subalbumChanges == rhs.subalbumChanges ||
      [lhs.subalbumChanges isEqual:rhs.subalbumChanges]) &&
      (lhs.assetChanges == rhs.assetChanges ||
      [lhs.assetChanges isEqual:rhs.assetChanges]) &&
      PTNAlbumSemanticallyEqual(lhs.beforeAlbum, rhs.beforeAlbum) &&
      PTNAlbumSemanticallyEqual(lhs.afterAlbum, rhs.afterAlbum));
}

SpecBegin(PTNInterceptingAssetManager)

__block PTNFakeAssetManager *underlyingAssetManager;
__block PTNInterceptingAssetManager *interceptingAssetManager;
__block RACSubject *interceptionMap;

beforeEach(^{
  underlyingAssetManager = [[PTNFakeAssetManager alloc] init];
  interceptionMap = [RACSubject subject];
  interceptingAssetManager =
      [[PTNInterceptingAssetManager alloc] initWithAssetManager:underlyingAssetManager
                                         interceptedDescriptors:interceptionMap];
});

context(@"album fetching", ^{
  __block NSURL *albumURL;
  __block NSURL *assetDescriptorURL;
  __block NSURL *subalbumDescriptorURL;
  __block NSURL *otherDescriptorURL;

  __block id<PTNDescriptor> assetDescriptor;
  __block id<PTNDescriptor> interceptingDescriptor;
  __block id<PTNDescriptor> otherDescriptor;
  __block id<PTNDescriptor> subalbumDescriptor;
  __block id<PTNAlbum> album;

  beforeEach(^{
    albumURL = [NSURL URLWithString:@"http://www.foo.com"];

    assetDescriptorURL = [NSURL URLWithString:@"http://www.foo.com/foo"];
    subalbumDescriptorURL = [NSURL URLWithString:@"http://www.foo.com/bar"];
    otherDescriptorURL = [NSURL URLWithString:@"http://www.foo.com/other"];

    assetDescriptor = PTNCreateDescriptor(assetDescriptorURL, @"foo", 0);
    subalbumDescriptor = PTNCreateDescriptor(subalbumDescriptorURL, @"bar", 0);

    interceptingDescriptor = PTNCreateDescriptor(nil, @"baz", 0);
    otherDescriptor = PTNCreateDescriptor(otherDescriptorURL, @"gaz", 0);

    album = [[PTNAlbum alloc] initWithURL:albumURL
                                subalbums:@[subalbumDescriptor, otherDescriptor]
                                   assets:@[assetDescriptor, otherDescriptor]];
  });

  it(@"should return an album identical to the original if it has no intercepted descriptors", ^{
    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return PTNChangesetSemanticallyEqual(changeset, returnedChangeset);
    });
  });

  it(@"should intercept given assets", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];


    NSArray *assets = @[interceptingDescriptor, otherDescriptor];
    id<PTNAlbum> interceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                        subalbums:album.subalbums
                                                           assets:assets];

    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:interceptedAlbum];;

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return PTNChangesetSemanticallyEqual(changeset, returnedChangeset);
    });
  });

  it(@"should intercept given assets", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];


    NSArray *assets = @[interceptingDescriptor, otherDescriptor];
    id<PTNAlbum> interceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                        subalbums:album.subalbums
                                                           assets:assets];

    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:interceptedAlbum];;

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return PTNChangesetSemanticallyEqual(changeset, returnedChangeset);
    });
  });

  it(@"should proxy index of intercepted asset via original asset", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL
                                withDescriptor:assetDescriptor];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return [returnedChangeset.afterAlbum.assets indexOfObject:interceptingDescriptor] == 0 &&
          [returnedChangeset.afterAlbum.assets indexOfObject:otherDescriptor] == 1 &&
          [returnedChangeset.afterAlbum.assets indexOfObject:assetDescriptor] == NSNotFound;
    });
  });

  it(@"should proxy index of intercepted subalbum via original asset", ^{
    [interceptionMap sendNext:@{subalbumDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [underlyingAssetManager serveDescriptorURL:subalbumDescriptorURL
                                withDescriptor:subalbumDescriptor];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return [returnedChangeset.afterAlbum.subalbums indexOfObject:interceptingDescriptor] == 0 &&
          [returnedChangeset.afterAlbum.subalbums indexOfObject:otherDescriptor] == 1 &&
          [returnedChangeset.afterAlbum.subalbums indexOfObject:subalbumDescriptor] == NSNotFound;
    });
  });

  it(@"should intercept given assets and subalbums", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                subalbumDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];
    [underlyingAssetManager serveDescriptorURL:subalbumDescriptorURL
                                withDescriptor:subalbumDescriptor];

    NSArray *subalbums = @[interceptingDescriptor, otherDescriptor];
    NSArray *assets = @[interceptingDescriptor, otherDescriptor];
    id<PTNAlbum> interceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                        subalbums:subalbums
                                                           assets:assets];

    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithAfterAlbum:interceptedAlbum];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return PTNChangesetSemanticallyEqual(changeset, returnedChangeset);
    });
  });

  it(@"should intercept given assets and subalbums on before album", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                subalbumDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    PTNAlbumChangeset *sentChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                                                        afterAlbum:album
                                                                   subalbumChanges:nil
                                                                      assetChanges:nil];
    [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:sentChangeset];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];
    [underlyingAssetManager serveDescriptorURL:subalbumDescriptorURL
                                withDescriptor:subalbumDescriptor];

    NSArray *subalbums = @[interceptingDescriptor, otherDescriptor];
    NSArray *assets = @[interceptingDescriptor, otherDescriptor];
    id<PTNAlbum> interceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                        subalbums:subalbums
                                                           assets:assets];
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAlbum
                                                                    afterAlbum:interceptedAlbum
                                                               subalbumChanges:nil
                                                                  assetChanges:nil];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return PTNChangesetSemanticallyEqual(changeset, returnedChangeset);
    });
  });

  it(@"should forward incremental changes on intercepted descriptors", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

    PTNIncrementalChanges *incrementalChanges = [PTNIncrementalChanges changesWithRemovedIndexes:nil
        insertedIndexes:[NSIndexSet indexSetWithIndex:0]
        updatedIndexes:[NSIndexSet indexSetWithIndex:0] moves:nil];
    PTNAlbumChangeset *sentChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:album
        afterAlbum:album subalbumChanges:nil assetChanges:incrementalChanges];
    [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:sentChangeset];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];



    NSArray *assets = @[interceptingDescriptor, otherDescriptor];
    id<PTNAlbum> interceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                        subalbums:album.subalbums
                                                           assets:assets];
    PTNIncrementalChanges *mappedChanges = [PTNIncrementalChanges changesWithRemovedIndexes:nil
        insertedIndexes:[NSIndexSet indexSetWithIndex:0] updatedIndexes:nil moves:nil];
    PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAlbum
                                                                    afterAlbum:interceptedAlbum
                                                               subalbumChanges:nil
                                                                  assetChanges:mappedChanges];

    expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return PTNChangesetSemanticallyEqual(changeset, returnedChangeset);
    });
  });

  it(@"should cache original descriptors", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                otherDescriptorURL: interceptingDescriptor}];
    [underlyingAssetManager serveDescriptorURL:otherDescriptorURL withDescriptor:otherDescriptor];
    [interceptionMap sendNext:@{otherDescriptorURL: interceptingDescriptor}];

    expect(values).will.sendValuesWithCount(3);
  });

  it(@"should forward errors on underlying descriptor", ^{
    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingAssetManager serveAlbumURL:albumURL withError:error];

    expect(values).to.sendError(error);
  });

  context(@"updates", ^{
    __block NSArray *interceptedSubalbums;
    __block NSArray *interceptedAssets;
    __block id<PTNAlbum> interceptedAssetAlbum;
    __block id<PTNAlbum> interceptedAssetAndAlbumAlbum;
    __block PTNIncrementalChanges *mappingChanges;

    beforeEach(^{
      interceptedSubalbums = @[interceptingDescriptor, otherDescriptor];
      interceptedAssets = @[interceptingDescriptor, otherDescriptor];
      interceptedAssetAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                  subalbums:album.subalbums
                                                     assets:interceptedSubalbums];
      interceptedAssetAndAlbumAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                          subalbums:interceptedSubalbums
                                                             assets:interceptedSubalbums];
      mappingChanges = [PTNIncrementalChanges changesWithRemovedIndexes:nil
          insertedIndexes:nil updatedIndexes:[NSIndexSet indexSetWithIndex:0] moves:nil];
    });

    it(@"should correctly handle regular album updates", ^{
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      PTNIncrementalChanges *incrementalChanges =
          [PTNIncrementalChanges changesWithRemovedIndexes:nil
                                           insertedIndexes:[NSIndexSet indexSetWithIndex:0]
                                            updatedIndexes:nil moves:nil];
      PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:album
          afterAlbum:album subalbumChanges:incrementalChanges assetChanges:incrementalChanges];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:changeset];

      expect(values).will.sendValuesWithCount(2);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        return PTNChangesetSemanticallyEqual(returnedChangeset, changeset);
      });
    });

    it(@"should correctly handle mapping updates", ^{
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                  subalbumDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:subalbumDescriptorURL
                                  withDescriptor:subalbumDescriptor];

      expect(values).will.sendValuesWithCount(3);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                             afterAlbum:interceptedAssetAlbum
                                        subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
      expect(values).will.matchValue(2, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAssetAlbum
                                             afterAlbum:interceptedAssetAndAlbumAlbum
                                        subalbumChanges:mappingChanges assetChanges:nil];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });

    it(@"should ignore updates form original album affecting only intercepted descriptors", ^{
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

      PTNAlbumChangeset *changesetOnIntercepted = [PTNAlbumChangeset changesetWithBeforeAlbum:album
          afterAlbum:album subalbumChanges:nil assetChanges:mappingChanges];
      [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:changesetOnIntercepted];
      PTNIncrementalChanges *changesOnNonIntercepted =
          [PTNIncrementalChanges changesWithRemovedIndexes:nil
                                           insertedIndexes:[NSIndexSet indexSetWithIndex:0]
                                            updatedIndexes:nil moves:nil];
      PTNAlbumChangeset *changesetOnNonIntercepted =
          [PTNAlbumChangeset changesetWithBeforeAlbum:album afterAlbum:album subalbumChanges:nil
                                         assetChanges:changesOnNonIntercepted];
      [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:changesetOnNonIntercepted];

      expect(values).will.sendValuesWithCount(3);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
        [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                         afterAlbum:interceptedAssetAlbum
                                    subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
      expect(values).will.matchValue(2, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAssetAlbum
                                             afterAlbum:interceptedAssetAlbum
                                        subalbumChanges:nil assetChanges:changesOnNonIntercepted];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });

    it(@"should send updates when mapping is removed", ^{
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];
      [interceptionMap sendNext:@{}];

      expect(values).will.sendValuesWithCount(3);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
        [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                         afterAlbum:interceptedAssetAlbum
                                    subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
      expect(values).will.matchValue(2, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
        [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAssetAlbum
                                         afterAlbum:album
                                    subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });

    it(@"should ignore mapping updates that don't affect this particular album", ^{
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

      NSURL *irrelevantURL = [NSURL URLWithString:@"http://www.foo.com/baz"];
      id<PTNDescriptor> irrelevantDescriptor = PTNCreateDescriptor(irrelevantURL, nil, 0);
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                  irrelevantURL: irrelevantDescriptor}];
      [underlyingAssetManager serveDescriptorURL:irrelevantURL withDescriptor:irrelevantDescriptor];


      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                  subalbumDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:subalbumDescriptorURL
                                  withDescriptor:subalbumDescriptor];

      expect(values).will.sendValuesWithCount(3);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
        [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                         afterAlbum:interceptedAssetAlbum
                                    subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
      expect(values).will.matchValue(2, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
        [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAssetAlbum
                                         afterAlbum:interceptedAssetAndAlbumAlbum
                                    subalbumChanges:mappingChanges assetChanges:nil];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });

    it(@"should not send updates on intercepted asset changes, but use them when map changes", ^{
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

      id<PTNDescriptor> updatedDescriptor = PTNCreateDescriptor(assetDescriptorURL, nil, 0);
      PTNAlbum *newAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                               subalbums:@[subalbumDescriptor, otherDescriptor]
                                                  assets:@[updatedDescriptor, otherDescriptor]];
      PTNAlbumChangeset *newChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:album
          afterAlbum:newAlbum subalbumChanges:nil assetChanges:mappingChanges];
      [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:newChangeset];
      
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL
                                  withDescriptor:updatedDescriptor];

      [interceptionMap sendNext:@{}];

      expect(values).will.sendValuesWithCount(3);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
        [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                         afterAlbum:interceptedAssetAlbum
                                    subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
      expect(values).will.matchValue(2, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
          [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAssetAlbum
                                           afterAlbum:newAlbum
                                      subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });
  });

  context(@"memory management", ^{
    it(@"should deallocate when reaching zero references after fetching a descriptor", ^{
      __block __weak PTNInterceptingAssetManager *weakInterceptingAssetManager;

      @autoreleasepool {
        PTNInterceptingAssetManager *assetManager =
            [[PTNInterceptingAssetManager alloc] initWithAssetManager:underlyingAssetManager
                                               interceptedDescriptors:interceptionMap];
        weakInterceptingAssetManager = assetManager;

        LLSignalTestRecorder *recorder = [[assetManager fetchAlbumWithURL:albumURL] testRecorder];
        [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
        [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
        [underlyingAssetManager serveDescriptorURL:assetDescriptorURL
                                    withDescriptor:assetDescriptor];

        expect(recorder).to.sendValuesWithCount(2);
      }

      expect(weakInterceptingAssetManager).to.beNil();
    });

    it(@"should unsubscribe from infinite signals", ^{
      __block __weak PTNInterceptingAssetManager *weakInterceptingAssetManager;
      __block RACDisposable *disposable;

      @autoreleasepool {
        id<PTNAssetManager> mockUnderlyingAssetManager =
            OCMProtocolMock(@protocol(PTNAssetManager));
        OCMStub([mockUnderlyingAssetManager fetchAlbumWithURL:albumURL])
            .andReturn([RACSignal never]);
        PTNInterceptingAssetManager *assetManager =
            [[PTNInterceptingAssetManager alloc] initWithAssetManager:mockUnderlyingAssetManager
                                               interceptedDescriptors:interceptionMap];
        weakInterceptingAssetManager = assetManager;

        disposable = [[assetManager fetchAlbumWithURL:albumURL] subscribeNext:^(id __unused x) {}];
      }

      expect(weakInterceptingAssetManager).to.beNil();
      expect(disposable.isDisposed).to.beTruthy();
    });
  });
});

context(@"asset fetching", ^{
  __block NSURL *url;
  __block id<PTNDescriptor> descriptor;
  __block id<PTNDescriptor> interceptingDescriptor;

  beforeEach(^{
    url = [NSURL URLWithString:@"http://www.foo.com"];
    interceptingDescriptor = PTNCreateDescriptor(nil, nil, 0);
    descriptor = PTNCreateDescriptor(url, @"bar", 0);
  });

  it(@"should return regular desciptor when it isn't intercepted", ^{
    LLSignalTestRecorder *values = [[interceptingAssetManager fetchDescriptorWithURL:url]
                                    testRecorder];

    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];

    expect(values).to.sendValues(@[descriptor]);
  });

  it(@"should return intercepting descriptor instead of original descriptor", ^{
    [interceptionMap sendNext:@{url: interceptingDescriptor}];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchDescriptorWithURL:url]
                                    testRecorder];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];

    expect(values).to.sendValues(@[interceptingDescriptor]);
  });

  it(@"should forward errors on underlying descriptor", ^{
    LLSignalTestRecorder *values = [[interceptingAssetManager fetchDescriptorWithURL:url]
                                    testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingAssetManager serveDescriptorURL:url withError:error];

    expect(values).to.sendError(error);
  });

  it(@"should handle updates correctly", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchDescriptorWithURL:url] testRecorder];

    id<PTNDescriptor> otherDescriptor = PTNCreateDescriptor(url, nil, 0);
    NSURL *otherURL = [NSURL URLWithString:@"http://www.foo.com/bar"];

    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:otherDescriptor];

    [interceptionMap sendNext:@{url: interceptingDescriptor}];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:otherDescriptor];

    [interceptionMap sendNext:@{url: otherDescriptor}];
    [interceptionMap sendNext:@{
      url: otherDescriptor,
      otherURL: descriptor
    }];
    [interceptionMap sendNext:@{}];

    [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];
    [underlyingAssetManager serveDescriptorURL:url withDescriptor:otherDescriptor];

    expect(values).to.sendValues(@[
      descriptor,
      otherDescriptor,
      interceptingDescriptor,
      otherDescriptor,
      descriptor,
      otherDescriptor
    ]);
  });

  context(@"memory management", ^{
    it(@"should deallocate when reaching zero references after fetching a descriptor", ^{
      __block __weak PTNInterceptingAssetManager *weakInterceptingAssetManager;

      @autoreleasepool {
        PTNInterceptingAssetManager *assetManager =
            [[PTNInterceptingAssetManager alloc] initWithAssetManager:underlyingAssetManager
                                               interceptedDescriptors:interceptionMap];
        weakInterceptingAssetManager = assetManager;

        LLSignalTestRecorder *recorder = [[assetManager fetchDescriptorWithURL:url] testRecorder];
        [underlyingAssetManager serveDescriptorURL:url withDescriptor:descriptor];
        [interceptionMap sendNext:@{url: interceptingDescriptor}];

        expect(recorder).to.sendValues(@[descriptor, interceptingDescriptor]);
      }

      expect(weakInterceptingAssetManager).to.beNil();
    });

    it(@"should unsubscribe from infinite signals", ^{
      __block __weak PTNInterceptingAssetManager *weakInterceptingAssetManager;
      __block RACDisposable *disposable;

      @autoreleasepool {
        id<PTNAssetManager> mockUnderlyingAssetManager =
            OCMProtocolMock(@protocol(PTNAssetManager));
        OCMStub([mockUnderlyingAssetManager fetchDescriptorWithURL:url])
            .andReturn([RACSignal never]);
        PTNInterceptingAssetManager *assetManager =
            [[PTNInterceptingAssetManager alloc] initWithAssetManager:mockUnderlyingAssetManager
                                               interceptedDescriptors:interceptionMap];
        weakInterceptingAssetManager = assetManager;

        disposable = [[assetManager fetchDescriptorWithURL:url] subscribeNext:^(id __unused x) {}];
      }

      expect(weakInterceptingAssetManager).to.beNil();
      expect(disposable.isDisposed).to.beTruthy();
    });
  });
});

context(@"image fetching", ^{
  __block id<PTNResizingStrategy> resizingStrategy;
  __block PTNImageFetchOptions *options;
  __block id<PTNDescriptor> descriptor;
  __block PTNImageRequest *request;

  beforeEach(^{
    resizingStrategy = OCMProtocolMock(@protocol(PTNResizingStrategy));
    options = OCMClassMock([PTNImageFetchOptions class]);
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    request = [[PTNImageRequest alloc] initWithDescriptor:descriptor
                                         resizingStrategy:resizingStrategy
                                                  options:options];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values = [[interceptingAssetManager fetchImageWithDescriptor:descriptor
        resizingStrategy:resizingStrategy options:options] testRecorder];

    PTNProgress *progress = [[PTNProgress alloc] initWithResult:@"foo"];

    [underlyingAssetManager serveImageRequest:request withProgressObjects:@[progress]];

    expect(values).will.sendValues(@[progress]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values = [[interceptingAssetManager fetchImageWithDescriptor:descriptor
        resizingStrategy:resizingStrategy options:options] testRecorder];

    PTNProgress *progress = [[PTNProgress alloc] initWithResult:@"foo"];
    NSError *error = [NSError lt_errorWithCode:1337];

    [underlyingAssetManager serveImageRequest:request withProgressObjects:@[progress]
                                 finallyError:error];

    expect(values).will.sendValues(@[progress]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

SpecEnd
