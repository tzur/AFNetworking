// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Category that provides a reactive functionality to On Demand Resources.
@interface NSBundle (OnDemandResources)

/// Begins access to bundle resource with the specified \c tags, this will try to download the
/// resources if necessary.
///
/// On subscription begins access to the on demand resources with \c tags. If the resources require
/// downloading, the signal delivers multiple \c LTProgress values indicating the progress of the
/// downloading. When the resource becomes available the signal sends \c LTProgress value carrying
/// an \c id<FBROnDemandResource> as \c result and then completes. If the resource is already
/// available, the signal sends \c LTProgress with the result. If fetching the requested resources
/// fails the signal errs with error code \c FBRErrorCodeOnDemandResourcesRequestFailed with an
/// underlying error specifying the failure reason.
///
/// @returns <tt>RACSignal<LTProgress<id<FBROnDemandResource>>></tt>
///
/// @note The requested resources are marked as in-use and are promised not to be purged, and
/// accessible by the bundle as long the resource object \c FBROnDemandResource is not deallocated.
///
/// @note The signal delivers on an arbitrary thread.
- (RACSignal *)fbr_beginAccessToResourcesWithTags:(NSSet<NSString *> *)tags;

/// Begins access to bundle resources with the specified \c tags only if they are available on
/// device.
///
/// On subscription begins access to the on demand resources with \c tags. The requested resources
/// are marked as in-use and are promised not to be purged. The signal completes and returns
/// \c id<FBROnDemandResource> if the resource is available on the device, otherwise returns \c nil.
///
/// @returns <tt>RACSignal<nullable id<FBROnDemandResource>></tt>
///
/// @note The requested resources are marked as in-use and are promised not to be purged, and
/// accessible by the bundle as long as the returned resource object \c id<FBROnDemandResource> is
/// not deallocated.
///
/// @note The signal delivers on an arbitrary thread.
- (RACSignal *)fbr_conditionallyBeginAccessToResourcesWithTags:(NSSet<NSString *> *)tags;

@end

NS_ASSUME_NONNULL_END
