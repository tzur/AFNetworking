// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <LTKit/LTProgress.h>

#import "FBROnDemandResource.h"

NS_ASSUME_NONNULL_BEGIN

/// An object representing the progress of On-Demand-Resources request, holding an
/// \c FBROnDemandResource as its \c result upon completion.
typedef LTProgress<id<FBROnDemandResource>> FBROnDemandResourceTaskProgress;

/// Category that provides a reactive functionality to On-Demand-Resources.
@interface NSBundle (OnDemandResources)

/// Begins access to bundle resource with the specified \c tags, this will try to download the
/// resources if necessary.
///
/// On subscription begins access to the On-Demand-Resources with the specified \c tags. If the
/// resources require downloading, the signal will initiate a request to download them and will
/// deliver multiple \c FBROnDemandResourceTaskProgress values indicating the progress of the task.
/// When the resource becomes available the signal sends another \c FBROnDemandResourceTaskProgress
/// value carrying an <tt>id<FBROnDemandResource></tt> as the \c result and then completes. If the
/// resource is already available on the device, the signal sends a single
/// \c FBROnDemandResourceTaskProgress with the result. If the task fails the signal errs with error
/// code \c FBRErrorCodeOnDemandResourcesRequestFailed and an underlying error specifying the
/// failure reason.
///
/// @returns <tt>RACSignal<FBROnDemandResourceTaskProgress></tt>
///
/// @note The requested resources are marked as in-use and are promised not to be purged, and
/// accessible by the bundle as long the resource object \c FBROnDemandResource is not deallocated.
///
/// @note The signal delivers on an arbitrary thread.
- (RACSignal<FBROnDemandResourceTaskProgress *> *)
    fbr_beginAccessToResourcesWithTags:(NSSet<NSString *> *)tags;

/// Begins access to bundle resources with the specified \c tags only if they are available on the
/// device.
///
/// On subscription begins access to the On-Demand-Resources with the specified \c tags. If the
/// resource is available on the device the signal will deliver a single
/// <tt>id<FBROnDemandResource></tt> value that can be used to access the resources and then
/// complete. Otherwise the signal will deliver a single \c nil value and then complete. The signal
/// does not err.
///
/// @returns <tt>RACSignal<nullable id<FBROnDemandResource>></tt>
///
/// @note The requested resources are marked as in-use and are promised not to be purged, and
/// accessible by the bundle as long as the returned resource object \c id<FBROnDemandResource> is
/// not deallocated.
///
/// @note The signal delivers on an arbitrary thread.
- (RACSignal<id<FBROnDemandResource>> *)
    fbr_conditionallyBeginAccessToResourcesWithTags:(NSSet<NSString *> *)tags;

@end

NS_ASSUME_NONNULL_END
