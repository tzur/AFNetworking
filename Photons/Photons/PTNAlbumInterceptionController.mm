// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbumInterceptionController.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTMappingRandomAccessCollection.h>

#import "PTNAlbum.h"
#import "PTNAlbumChangeset.h"
#import "PTNDescriptor.h"
#import "PTNIncrementalChanges.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAlbumInterceptionController

+ (nullable PTNAlbumChangeset *)changesetWithParameters:
    (PTNAlbumInterceptionChangeParameters)parameters {
  if (parameters.changeInvoker == PTNAlbumInterceptionChangeInvokerUnderlyingAlbum ||
      parameters.changeInvoker == PTNAlbumInterceptionChangeInvokerNone) {
    return [[self class] interceptedChangesetFromUnderlyingAlbumChange:parameters];
  } else if (parameters.changeInvoker == PTNAlbumInterceptionChangeInvokerMapping) {
    return [[self class] interceptedChangesetFromMappingChange:parameters];
  } else {
    LTAssert(NO, @"Unrecognized album interception change invoker: %lu",
             (unsigned long)parameters.changeInvoker);
  }
}

+ (nullable PTNAlbumChangeset *)interceptedChangesetFromUnderlyingAlbumChange:
    (PTNAlbumInterceptionChangeParameters)parameters {
  PTNIncrementalChanges * _Nullable nonInterceptedSubalbumChanges =
        [[self class] stripInterceptedUpdates:parameters.changeset.subalbumChanges
                               inteceptionMap:parameters.interceptionMap
                           originalCollection:parameters.changeset.afterAlbum.subalbums];
  PTNIncrementalChanges * _Nullable nonInterceptedAssetChanges =
      [[self class] stripInterceptedUpdates:parameters.changeset.assetChanges
                             inteceptionMap:parameters.interceptionMap
                         originalCollection:parameters.changeset.afterAlbum.assets];

  if ((parameters.changeset.subalbumChanges || parameters.changeset.assetChanges) &&
      !nonInterceptedSubalbumChanges && !nonInterceptedAssetChanges) {
    return nil;
  }

  id<PTNAlbum> _Nullable interceptingBeforeAlbum =
      [[self class] interceptingAlbum:parameters.changeset.beforeAlbum
                       inteceptionMap:parameters.interceptionMap
                          originalMap:parameters.originalMap];
  id<PTNAlbum> interceptingAfterAlbum =
      [[self class] interceptingAlbum:parameters.changeset.afterAlbum
                       inteceptionMap:parameters.interceptionMap
                          originalMap:parameters.originalMap];
  return [PTNAlbumChangeset changesetWithBeforeAlbum:interceptingBeforeAlbum
                                          afterAlbum:interceptingAfterAlbum
                                     subalbumChanges:nonInterceptedSubalbumChanges
                                        assetChanges:nonInterceptedAssetChanges];
}

+ (nullable PTNAlbumChangeset *)interceptedChangesetFromMappingChange:
    (PTNAlbumInterceptionChangeParameters)parameters {
  if ([parameters.interceptionMap isEqual:parameters.previousInterceptionMap]) {
    // Updates to the original mapping without changes to the interception mapping should not invoke
    // a new changeset.
    return nil;
  }

  NSIndexSet *updatedAlbumIndexes =
      [[self class] mappingUpdatesInCollection:parameters.changeset.afterAlbum.subalbums
                       previousInterceptionMap:parameters.previousInterceptionMap
                               interceptionMap:parameters.interceptionMap
                           previousOriginalMap:parameters.previousOriginalMap
                                   originalMap:parameters.originalMap];
  NSIndexSet *updatedAssetIndexes =
      [[self class] mappingUpdatesInCollection:parameters.changeset.afterAlbum.assets
                       previousInterceptionMap:parameters.previousInterceptionMap
                               interceptionMap:parameters.interceptionMap
                           previousOriginalMap:parameters.previousOriginalMap
                                   originalMap:parameters.originalMap];

  if (!updatedAlbumIndexes.count && !updatedAssetIndexes.count) {
    return nil;
  }

  PTNIncrementalChanges * _Nullable interceptedSubalbumChanges = updatedAlbumIndexes.count ?
      [PTNIncrementalChanges changesWithRemovedIndexes:nil insertedIndexes:nil
                                        updatedIndexes:updatedAlbumIndexes moves:nil] : nil;
  PTNIncrementalChanges * _Nullable interceptedAssetChanges = updatedAssetIndexes.count ?
      [PTNIncrementalChanges changesWithRemovedIndexes:nil insertedIndexes:nil
                                        updatedIndexes:updatedAssetIndexes moves:nil] : nil;

  id<PTNAlbum> interceptingBeforeAlbum =
      [[self class] interceptingAlbum:parameters.changeset.afterAlbum
                       inteceptionMap:parameters.previousInterceptionMap
                          originalMap:parameters.previousOriginalMap];
  id<PTNAlbum> interceptingAfterAlbum =
      [[self class] interceptingAlbum:parameters.changeset.afterAlbum
                       inteceptionMap:parameters.interceptionMap
                          originalMap:parameters.originalMap];
  return [PTNAlbumChangeset changesetWithBeforeAlbum:interceptingBeforeAlbum
                                          afterAlbum:interceptingAfterAlbum
                                     subalbumChanges:interceptedSubalbumChanges
                                        assetChanges:interceptedAssetChanges];
}

+ (nullable PTNIncrementalChanges *)stripInterceptedUpdates:
    (nullable PTNIncrementalChanges *)changes
    inteceptionMap:(PTNDescriptorBidirectionalMap *)interceptionMap
    originalCollection:(id<LTRandomAccessCollection>)collection {
  if (!changes.updatedIndexes) {
    return changes;
  }

  NSMutableIndexSet * _Nullable updatedIndexes = [NSMutableIndexSet indexSet];

  [changes.updatedIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL __unused *stop) {
    LTAssert(idx < collection.count, @"Update index: %lu out of bounds of given collection %@",
             (unsigned long)idx, collection);
    id<PTNDescriptor> descriptor = collection[idx];
    if (!interceptionMap[descriptor.ptn_identifier]) {
      [updatedIndexes addIndex:idx];
    }
  }];

  if (!updatedIndexes.count) {
    // The underlying \c PTNIncrementalChanges object uses \c nil instead of every zero-length set.
    updatedIndexes = nil;
  }

  if (!changes.removedIndexes && !changes.insertedIndexes && !updatedIndexes && !changes.moves) {
    // The underlying \c PTNAlbumChangeset object uses \c nil instead of every empty
    // \c PTNIncrementalChanges object.
    return nil;
  }

  return [PTNIncrementalChanges changesWithRemovedIndexes:changes.removedIndexes
                                          insertedIndexes:changes.insertedIndexes
                                           updatedIndexes:[updatedIndexes copy]
                                                    moves:changes.moves];
}

+ (NSIndexSet *)mappingUpdatesInCollection:(id<LTRandomAccessCollection>)collection
                   previousInterceptionMap:(PTNDescriptorBidirectionalMap *)previousInterceptionMap
                           interceptionMap:(PTNDescriptorBidirectionalMap *)interceptionMap
                       previousOriginalMap:(PTNDescriptorBidirectionalMap *)previousOriginalMap
                               originalMap:(PTNDescriptorBidirectionalMap *)originalMap {
  NSMutableIndexSet *updatedIndexes = [NSMutableIndexSet indexSet];

  NSArray<id<PTNDescriptor>> *alteredDescriptors =
      [[self class] symmetricDifference:previousInterceptionMap.allValues
                                   with:interceptionMap.allValues];

  NSArray<NSURL *> *alteredKeys =
      [[self class] symmetricDifference:previousInterceptionMap.allKeys
                                   with:interceptionMap.allKeys];

  NSArray<NSURL *> *alteredDescriptorKeys = [alteredDescriptors.rac_sequence
      map:^NSURL *(id<PTNDescriptor> descriptor) {
        // Originating in a symmetric difference, a descriptor will be in exactly one of the maps.
        return [interceptionMap keyForObject:descriptor] ?:
            [previousInterceptionMap keyForObject:descriptor];
      }].array;

  for (NSURL *identifier in [alteredKeys arrayByAddingObjectsFromArray:alteredDescriptorKeys]) {
    // Indentifier should be in one of the original maps or in both, if it's in both it should point
    // to the same asset, so it doesn't matter which one returns it.
    id<PTNDescriptor> originalDescriptor = originalMap[identifier] ?:
        previousOriginalMap[identifier];
    NSUInteger indexPath = [collection indexOfObject:originalDescriptor];
    if (indexPath != NSNotFound) {
      [updatedIndexes addIndex:indexPath];
    }
  }

  return [updatedIndexes copy];
}

+ (NSArray *)symmetricDifference:(NSArray *)first with:(NSArray *)second {
  return [[first arrayByAddingObjectsFromArray:second].rac_sequence filter:^BOOL(id value) {
    return !([first containsObject:value] && [second containsObject:value]);
  }].array;
}

#pragma mark -
#pragma mark Intercepting Album
#pragma mark -

+ (nullable id<PTNAlbum>)interceptingAlbum:(nullable id<PTNAlbum>)album
                            inteceptionMap:(PTNDescriptorBidirectionalMap *)interceptionMap
                               originalMap:(PTNDescriptorBidirectionalMap *)originalMap {
  if (!album) {
    return nil;
  }

  id<LTRandomAccessCollection> interceptingSubalbums =
      [[self class] interceptingCollection:album.subalbums
                            inteceptionMap:interceptionMap originalMap:originalMap];
  id<LTRandomAccessCollection> interceptingAssets =
      [[self class] interceptingCollection:album.assets
                            inteceptionMap:interceptionMap originalMap:originalMap];

  return [[PTNAlbum alloc] initWithURL:album.url subalbums:interceptingSubalbums
                                assets:interceptingAssets];
}

+ (id<LTRandomAccessCollection>)interceptingCollection:(id<LTRandomAccessCollection>)collection
    inteceptionMap:(PTNDescriptorBidirectionalMap *)interceptionMap
    originalMap:(PTNDescriptorBidirectionalMap *)originalMap {
  return [[LTMappingRandomAccessCollection alloc] initWithCollection:collection
      forwardMapBlock:^id<PTNDescriptor>(id<PTNDescriptor> descriptor) {
        return interceptionMap[descriptor.ptn_identifier] ?: descriptor;
      } reverseMapBlock:^id<PTNDescriptor> _Nullable (id<PTNDescriptor> descriptor) {
        NSURL * _Nullable interceptedIdentifer = [interceptionMap keyForObject:descriptor];
        if (interceptedIdentifer) {
          return originalMap[interceptedIdentifer];
        }

        // In a case where \c descriptor is an intercepted descriptor, passing it forward to the
        // underlying collection will return the wrong result, since it's a valid descriptor in the
        // underlying collection, but an invalid one in the mapped collection. e.g. If the original
        // collection is <tt>{a, b}</tt>, the interception map deemed <tt>b->c</tt> and the new
        // collection is <tt>{a, c}</tt> the indexes should be as follows: the index of \c a remains
        // the index of \c a in the original collection, the index of \c c is equivalent to the
        // index of \c b in the original collection and the index of \c b should be \c NSNotFound.
        if ([originalMap.allValues containsObject:descriptor]) {
          return nil;
        }

        return descriptor;
      }];
}

@end

NS_ASSUME_NONNULL_END
