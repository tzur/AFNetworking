// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNDescriptor;

@class PTNAlbumChangeset;

/// Bidirectional mapping of \c NSURL identifiers of Photons assets to intercept and the
/// \c PTNDescriptors to inject in their place.
typedef LTBidirectionalMap<NSURL *, id<PTNDescriptor>> PTNDescriptorBidirectionalMap;

/// Possible invokers of changes in the intercepted album fetch.
typedef NS_ENUM(NSUInteger, PTNAlbumInterceptionChangeInvoker) {
  /// Changes caused by an update in the interception mapping.
  PTNAlbumInterceptionChangeInvokerMapping,
  /// Changes cause by an update in the underlying intercepted album.
  PTNAlbumInterceptionChangeInvokerUnderlyingAlbum,
  /// Changes caused by no update but rather from the initial changeset and mapping combination.
  PTNAlbumInterceptionChangeInvokerNone
};

/// Album intercepting change parameters containing \c interceptionMap as a mapping between \c NSURL
/// identifiers and \c PTNDescriptor objects to inject in their place, \c previousInterceptionMap as
/// the last \c interceptionMapping, prior to the latest one, \c originalMap as a mapping between
/// \c NSURL identifiers and the \c PTNDescriptor objects they normally represent in the Photons
/// framework, \c previousOriginalMap as the last \c originalMap prior to the latest one,
/// \c changeset as the latest \c PTNAlbumChangeset sent by the underlying album fetch and
/// \c changeInvoker as an indicator of the cause for the possible update in the intercepted album
/// fetch.
struct PTNAlbumInterceptionChangeParameters {
  /// Latest mapping from \c NSURL identifiers to \c PTNDescriptor objects to inject in their place.
  PTNDescriptorBidirectionalMap *interceptionMap;
  /// Previous mapping from \c NSURL identifiers to \c PTNDescriptor objects to inject in their
  /// place as it was before \c interceptionMap was sent.
  PTNDescriptorBidirectionalMap *previousInterceptionMap;
  /// Latest mapping from \c NSURL identifiers to the \c PTNDescriptor they originally represent in
  /// the Photons framework.
  PTNDescriptorBidirectionalMap *originalMap;
  /// Previous mapping from \c NSURL identifiers to the \c PTNDescriptor they originally represent
  /// in the Photons framework as it was before \c originalMap was sent.
  PTNDescriptorBidirectionalMap *previousOriginalMap;
  /// Latest \c PTNAlbumChangeset sent by the underlying album.
  PTNAlbumChangeset *changeset;
  /// Invoker of the possible update required in the intercepted album.
  PTNAlbumInterceptionChangeInvoker changeInvoker;
};

/// Class encapsulating album interception logic. An instance of this class should be initialized
/// for every change in the latest interception mapping, original mapping and album changeset
/// combination. It then supplies a simple interface regarding whether an update should be sent on
/// the intercepting album fetch signal, and with which changeset.
@interface PTNAlbumInterceptionController : NSObject

/// The \c PTNAlbumChangeset to be sent on an intercepting album fetch signal given the latest
/// interception mapping, original mapping and album changeset combination or \c nil the given
/// parameters do not necessitate a new \c PTNAlbumChangeset to be sent.
+ (nullable PTNAlbumChangeset *)changesetWithParameters:
    (PTNAlbumInterceptionChangeParameters)parameters;

@end

NS_ASSUME_NONNULL_END
