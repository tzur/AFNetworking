// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Update status tweak name when an associated \c LABTweakCollectionsProvider is not updating its
/// collections and the last update was successful.
extern NSString * const kLABUpdateStatusTweakNameStable;

/// Update status tweak name when an associated \c LABTweakCollectionsProvider is updating its
/// collection.
extern NSString * const kLABUpdateStatusTweakNameUpdating;

/// Update status tweak name when an associated \c LABTweakCollectionsProvider had failed updating
/// its collection.
extern NSString * const kLABUpdateStatusTweakNameStableUpdateFailed;

/// Name of a reset tweak, used to reset a collections provider.
extern NSString * const kLABResetTweakName;

/// Name of an update tweak, used to update a collections provider.
extern NSString * const kLABUpdateTweakName;

NS_ASSUME_NONNULL_END
