// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@class FBTweakCollection;

/// Implementers of this protocol provide FBTweak collections and have the ability to update them.
@protocol LABTweakCollectionsProvider <NSObject>

@optional

/// Updates the provider with the latest available \c collections. The returned signal completes
/// when the update completes successfully or errs with \c LABErrorCodeTweaksCollectionsUpdateFailed
/// if the update fails.
///
/// If new information was received from the remote resource, the property \c collections may
/// change. Values are sent on the main thread.
///
/// @return RACSignal<>
- (RACSignal *)updateCollections;

@required

/// Resets all tweaks in \c collections. The reset is done synchronously. Once this method returns
/// all tweaks in \c collections return to their default values.
- (void)resetTweaks;

/// FBTweak collections available from the receiver.
///
/// @note This property is KVO-compliant. Values may be delivered on an arbitrary thread.
@property (readonly, nonatomic) NSArray<FBTweakCollection *> *collections;

@end

NS_ASSUME_NONNULL_END
