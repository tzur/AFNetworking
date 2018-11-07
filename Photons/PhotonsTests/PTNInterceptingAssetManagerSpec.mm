// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNInterceptingAssetManager.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTProgress.h>
#import <LTKit/LTRandomAccessCollection.h>

#import "NSErrorCodes+Photons.h"
#import "PTNAVAssetFetchOptions.h"
#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNAudiovisualAsset.h"
#import "PTNFakeAssetManager.h"
#import "PTNImageDataAsset.h"
#import "PTNImageFetchOptions.h"
#import "PTNIncrementalChanges.h"
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
  __block id<PTNDescriptor> otherInterceptingDescriptor;
  __block id<PTNDescriptor> otherDescriptor;
  __block id<PTNDescriptor> subalbumDescriptor;
  __block id<PTNAlbum> album;

  beforeEach(^{
    albumURL = [NSURL URLWithString:@"http://www.foo.com"];

    assetDescriptorURL = [NSURL URLWithString:@"http://www.foo.com/foo"];
    subalbumDescriptorURL = [NSURL URLWithString:@"http://www.foo.com/bar"];
    otherDescriptorURL = [NSURL URLWithString:@"http://www.foo.com/other"];

    assetDescriptor = PTNCreateDescriptor(assetDescriptorURL, @"foo", 0, nil);
    subalbumDescriptor = PTNCreateDescriptor(subalbumDescriptorURL, @"bar", 0, nil);

    interceptingDescriptor = PTNCreateDescriptor(nil, @"baz", 0, nil);
    otherInterceptingDescriptor = PTNCreateDescriptor(nil, @"caz", 0, nil);
    otherDescriptor = PTNCreateDescriptor(otherDescriptorURL, @"gaz", 0, nil);

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
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

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
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

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
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL
                                withDescriptor:assetDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return [returnedChangeset.afterAlbum.assets indexOfObject:interceptingDescriptor] == 0 &&
          [returnedChangeset.afterAlbum.assets indexOfObject:otherDescriptor] == 1 &&
          [returnedChangeset.afterAlbum.assets indexOfObject:assetDescriptor] == NSNotFound;
    });
  });

  it(@"should proxy index of intercepted asset via original asset", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL
                                withDescriptor:assetDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return [returnedChangeset.afterAlbum.assets indexOfObject:interceptingDescriptor] == 0 &&
          [returnedChangeset.afterAlbum.assets indexOfObject:otherDescriptor] == 1 &&
          [returnedChangeset.afterAlbum.assets indexOfObject:assetDescriptor] == NSNotFound;
    });
  });

  it(@"should not proxy index of intercepted subalbum when original asset can't be fetched", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL
        withError:[NSError lt_errorWithCode:1337]];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

    expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
      return [returnedChangeset.afterAlbum.subalbums
              indexOfObject:interceptingDescriptor] == NSNotFound &&
          [returnedChangeset.afterAlbum.subalbums indexOfObject:otherDescriptor] == 1 &&
          [returnedChangeset.afterAlbum.subalbums indexOfObject:assetDescriptor] == NSNotFound;
    });
  });

  it(@"should intercept given assets and subalbums", ^{
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                subalbumDescriptorURL: otherInterceptingDescriptor}];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];
    [underlyingAssetManager serveDescriptorURL:subalbumDescriptorURL
                                withDescriptor:subalbumDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

    NSArray *subalbums = @[otherInterceptingDescriptor, otherDescriptor];
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
                                subalbumDescriptorURL: otherInterceptingDescriptor}];
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];
    [underlyingAssetManager serveDescriptorURL:subalbumDescriptorURL
                                withDescriptor:subalbumDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    PTNAlbumChangeset *sentChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                                                        afterAlbum:album
                                                                   subalbumChanges:nil
                                                                      assetChanges:nil];
    [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:sentChangeset];

    NSArray *subalbums = @[otherInterceptingDescriptor, otherDescriptor];
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
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

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
    [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

    LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                    testRecorder];

    [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
    [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                otherDescriptorURL: otherInterceptingDescriptor}];
    [underlyingAssetManager serveDescriptorURL:otherDescriptorURL withDescriptor:otherDescriptor];
    [interceptionMap sendNext:@{otherDescriptorURL: otherInterceptingDescriptor}];

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
    __block NSArray *otherInterceptedSubalbums;
    __block NSArray *interceptedAssets;
    __block id<PTNAlbum> interceptedAssetAlbum;
    __block id<PTNAlbum> interceptedAssetAndAlbumAlbum;
    __block PTNIncrementalChanges *mappingChanges;

    beforeEach(^{
      interceptedSubalbums = @[interceptingDescriptor, otherDescriptor];
      otherInterceptedSubalbums = @[otherInterceptingDescriptor, otherDescriptor];
      interceptedAssets = @[interceptingDescriptor, otherDescriptor];
      interceptedAssetAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                  subalbums:album.subalbums
                                                     assets:interceptedSubalbums];
      interceptedAssetAndAlbumAlbum = [[PTNAlbum alloc] initWithURL:albumURL
                                                          subalbums:otherInterceptedSubalbums
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
                                  subalbumDescriptorURL: otherInterceptingDescriptor}];
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
      id<PTNDescriptor> irrelevantDescriptor = PTNCreateDescriptor(irrelevantURL, nil, 0, nil);
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                  irrelevantURL: irrelevantDescriptor}];
      [underlyingAssetManager serveDescriptorURL:irrelevantURL withDescriptor:irrelevantDescriptor];

      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor,
                                  subalbumDescriptorURL: otherInterceptingDescriptor}];
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

      id<PTNDescriptor> updatedDescriptor = PTNCreateDescriptor(assetDescriptorURL, nil, 0, nil);
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

    it(@"should correctly handle updates on indexes outside original range", ^{
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];

      PTNAlbum *newAlbum = [[PTNAlbum alloc] initWithURL:albumURL
          subalbums:@[subalbumDescriptor, otherDescriptor]
          assets:@[assetDescriptor, otherDescriptor, otherDescriptor]];
      PTNIncrementalChanges *outOfBoundsChanges =
          [PTNIncrementalChanges changesWithRemovedIndexes:nil
                                           insertedIndexes:[NSIndexSet indexSetWithIndex:1]
                                            updatedIndexes:[NSIndexSet indexSetWithIndex:2]
                                                     moves:nil];
      PTNAlbumChangeset *newChangeset = [PTNAlbumChangeset changesetWithBeforeAlbum:album
          afterAlbum:newAlbum subalbumChanges:nil assetChanges:outOfBoundsChanges];
      [underlyingAssetManager serveAlbumURL:albumURL withAlbumChangeset:newChangeset];

      expect(values).will.sendValuesWithCount(2);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset =
            [PTNAlbumChangeset changesetWithAfterAlbum:interceptedAssetAlbum];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        NSArray *updatedInterceptedAssets = @[
          interceptingDescriptor,
          otherDescriptor,
          otherDescriptor
        ];
        id<PTNAlbum> updatedInterceptedAfterAlbum =
            [[PTNAlbum alloc] initWithURL:albumURL subalbums:album.subalbums
                                   assets:updatedInterceptedAssets];
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAssetAlbum
                                             afterAlbum:updatedInterceptedAfterAlbum
                                        subalbumChanges:nil assetChanges:outOfBoundsChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });

    it(@"should correctly handle mapping updates on the same intercepted asset", ^{
      id<PTNDescriptor> otherInterceptingDescriptor = PTNCreateDescriptor(@"qux");

      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

      [interceptionMap sendNext:@{assetDescriptorURL: otherInterceptingDescriptor}];

      PTNAlbum *interceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
            subalbums:@[subalbumDescriptor, otherDescriptor]
            assets:@[interceptingDescriptor, otherDescriptor]];
      PTNAlbum *otherInterceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
            subalbums:@[subalbumDescriptor, otherDescriptor]
            assets:@[otherInterceptingDescriptor, otherDescriptor]];

      expect(values).will.sendValuesWithCount(3);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                             afterAlbum:interceptedAlbum
                                        subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
      expect(values).will.matchValue(2, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAlbum
                                             afterAlbum:otherInterceptedAlbum
                                        subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });

    it(@"should correctly handle mapping updates of the same intercepting asset", ^{
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      [underlyingAssetManager serveAlbumURL:albumURL withAlbum:album];
      [interceptionMap sendNext:@{assetDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:assetDescriptorURL withDescriptor:assetDescriptor];

      [interceptionMap sendNext:@{otherDescriptorURL: interceptingDescriptor}];
      [underlyingAssetManager serveDescriptorURL:otherDescriptorURL withDescriptor:otherDescriptor];

      PTNAlbum *interceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
            subalbums:@[subalbumDescriptor, otherDescriptor]
            assets:@[interceptingDescriptor, otherDescriptor]];
      PTNAlbum *otherInterceptedAlbum = [[PTNAlbum alloc] initWithURL:albumURL
            subalbums:@[subalbumDescriptor, interceptingDescriptor]
            assets:@[assetDescriptor, interceptingDescriptor]];

      PTNIncrementalChanges *assetMappingChanges = [PTNIncrementalChanges
          changesWithRemovedIndexes:nil insertedIndexes:nil
          updatedIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] moves:nil];
      PTNIncrementalChanges *albumMappingChanges = [PTNIncrementalChanges
          changesWithRemovedIndexes:nil insertedIndexes:nil
          updatedIndexes:[NSIndexSet indexSetWithIndex:1] moves:nil];

      expect(values).will.sendValuesWithCount(3);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                             afterAlbum:interceptedAlbum
                                        subalbumChanges:nil assetChanges:mappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
      expect(values).will.matchValue(2, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *interceptedChangeset =
            [PTNAlbumChangeset changesetWithBeforeAlbum:interceptedAlbum
                                             afterAlbum:otherInterceptedAlbum
                                        subalbumChanges:albumMappingChanges
                                           assetChanges:assetMappingChanges];
        return PTNChangesetSemanticallyEqual(returnedChangeset, interceptedChangeset);
      });
    });

    it(@"should not skip album updates even if sent prior to mapping", ^{
      PTNAlbumChangeset *changeset = [PTNAlbumChangeset changesetWithBeforeAlbum:album
                                                                      afterAlbum:album
                                                                 subalbumChanges:nil
                                                                    assetChanges:nil];
      RACSignal *albumUpdates = [[RACSignal
           return:[PTNAlbumChangeset changesetWithAfterAlbum:album]]
           concat:[RACSignal return:changeset]];

      id<PTNAssetManager> assetManager = OCMProtocolMock(@protocol(PTNAssetManager));
      OCMStub([assetManager fetchAlbumWithURL:OCMOCK_ANY]).andReturn(albumUpdates);

      interceptingAssetManager =
          [[PTNInterceptingAssetManager alloc] initWithAssetManager:assetManager
                                             interceptedDescriptors:[RACSignal empty]];
      LLSignalTestRecorder *values = [[interceptingAssetManager fetchAlbumWithURL:albumURL]
                                      testRecorder];

      expect(values).will.sendValuesWithCount(2);
      expect(values).will.matchValue(0, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        PTNAlbumChangeset *afterAlbumChangeset = [PTNAlbumChangeset changesetWithAfterAlbum:album];
        return PTNChangesetSemanticallyEqual(returnedChangeset, afterAlbumChangeset);
      });
      expect(values).will.matchValue(1, ^BOOL(PTNAlbumChangeset *returnedChangeset) {
        return PTNChangesetSemanticallyEqual(returnedChangeset, changeset);
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
    interceptingDescriptor = PTNCreateDescriptor(nil, nil, 0, nil);
    descriptor = PTNCreateDescriptor(url, @"bar", 0, nil);
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

    id<PTNDescriptor> otherDescriptor = PTNCreateDescriptor(url, nil, 0, nil);
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

    LTProgress *progress = [[LTProgress alloc] initWithResult:@"foo"];

    [underlyingAssetManager serveImageRequest:request withProgressObjects:@[progress]];

    expect(values).will.sendValues(@[progress]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values = [[interceptingAssetManager fetchImageWithDescriptor:descriptor
        resizingStrategy:resizingStrategy options:options] testRecorder];

    LTProgress *progress = [[LTProgress alloc] initWithResult:@"foo"];
    NSError *error = [NSError lt_errorWithCode:1337];

    [underlyingAssetManager serveImageRequest:request withProgressObjects:@[progress]
                                 finallyError:error];

    expect(values).will.sendValues(@[progress]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

context(@"AVAsset fetching", ^{
  __block PTNAVAssetFetchOptions *options;
  __block id<PTNDescriptor> descriptor;
  __block PTNAVAssetRequest *request;
  __block id<PTNAudiovisualAsset> videoAsset;

  beforeEach(^{
    options = OCMClassMock([PTNImageFetchOptions class]);
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    videoAsset = OCMProtocolMock(@protocol(PTNAudiovisualAsset));
    request = [[PTNAVAssetRequest alloc] initWithDescriptor:descriptor options:options];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchAVAssetWithDescriptor:descriptor options:options]
         testRecorder];

    [underlyingAssetManager serveAVAssetRequest:request withProgress:@[] videoAsset:videoAsset];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:videoAsset]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchAVAssetWithDescriptor:descriptor options:options]
         testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];

    [underlyingAssetManager serveAVAssetRequest:request withProgress:@[@0.666] finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.666]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

context(@"image data fetching", ^{
  __block id<PTNAssetDescriptor> descriptor;
  __block id<PTNImageDataAsset> imageDataAsset;
  __block PTNImageDataRequest *request;

  beforeEach(^{
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    imageDataAsset = OCMProtocolMock(@protocol(PTNImageDataAsset));
    request = [[PTNImageDataRequest alloc] initWithAssetDescriptor:descriptor];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchImageDataWithDescriptor:descriptor] testRecorder];

    [underlyingAssetManager serveImageDataRequest:request withProgress:@[]
                                   imageDataAsset:imageDataAsset];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:imageDataAsset]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchImageDataWithDescriptor:descriptor] testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingAssetManager serveImageDataRequest:request withProgress:@[@0.123]
                                     finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.123]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

context(@"AV preview fetching", ^{
  __block PTNAVAssetFetchOptions *options;
  __block id<PTNDescriptor> descriptor;
  __block PTNAVPreviewRequest *request;

  beforeEach(^{
    options = OCMClassMock([PTNImageFetchOptions class]);
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    request = [[PTNAVPreviewRequest alloc] initWithDescriptor:descriptor options:options];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchAVPreviewWithDescriptor:descriptor options:options]
         testRecorder];
    AVPlayerItem *playerItem = OCMClassMock([AVPlayerItem class]);

    [underlyingAssetManager serveAVPreviewRequest:request withProgress:@[] playerItem:playerItem];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:playerItem]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchAVPreviewWithDescriptor:descriptor options:options]
         testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];

    [underlyingAssetManager serveAVPreviewRequest:request withProgress:@[@0.666]
                                     finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.666]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

context(@"av data fetching", ^{
  __block id<PTNAssetDescriptor> descriptor;
  __block PTNAVDataRequest *request;

  beforeEach(^{
    descriptor = OCMProtocolMock(@protocol(PTNDescriptor));
    request = [[PTNAVDataRequest alloc] initWithDescriptor:descriptor];
  });

  it(@"should forward values from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchAVDataWithDescriptor:descriptor] testRecorder];
    id<PTNAVDataAsset> avDataAsset = OCMProtocolMock(@protocol(PTNAVDataAsset));

    [underlyingAssetManager serveAVDataRequest:request withProgress:@[] avDataAsset:avDataAsset];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithResult:avDataAsset]]);
    expect(values).will.complete();
  });

  it(@"should forward errors from underlying asset manager", ^{
    LLSignalTestRecorder *values =
        [[interceptingAssetManager fetchAVDataWithDescriptor:descriptor] testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingAssetManager serveAVDataRequest:request withProgress:@[@0.123] finallyError:error];

    expect(values).will.sendValues(@[[[LTProgress alloc] initWithProgress:0.123]]);
    expect(values).will.error();
    expect(values.error).will.equal(error);
  });
});

SpecEnd
