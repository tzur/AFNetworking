// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXSubscriptionManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds reactive signal based interface to \c SPXSubscriptionManager.
///
/// @see SPXSubscriptionManager, SPXSubscriptionManagerDelegate, SPXAlertViewModel.
@interface SPXSubscriptionManager (RACSignalSupport)

#pragma mark -
#pragma mark Operations
#pragma mark -

/// Fetches metadata for the products specified by \c productIdentifiers. It also takes care of
/// displaying failure alert, giving the user the option to try again, send a feedback email or
/// abort the operation.
///
/// Returns a signal that fetches products metadata on subscription. If fetching has completed
/// without errors during the request the signal will deliver a single \c NSDictioncary value
/// mapping from product identifier to its metadata as \c BZRProduct value and then completes.
/// Note that this dictionary may be empty if the underlying infrastructure reported no error but
/// provided no metadata. If there was an error during the metadata fetching the manager will ask
/// its delegate to present an alert suggesting the user to try again, send a feedback email or
/// abort the operation. The signal will err if the user choses to cancel the operation or after
/// feedback mail composition has completed.
///
/// @note All events are delivered on the main thread.
- (RACSignal<NSDictionary<NSString *, BZRProduct *> *> *)fetchProductsInfo:
    (NSSet<NSString *> *)productIdentifiers;

/// Purchases the subscription product specified by \c productIdentifier. It also takes care of
/// displaying failure alert, giving the user the option to try again, send a feedback email or
/// abort the operation.
///
/// Returns a signal that purchases the specified product on subscription. If purchase has completed
/// successfully the signal will deliver a single \c BZRSubscriptionInfo value describing the user's
/// active subscription and then complete. If the request was actively cancelled the signal will
/// complete without sending any value. If there was an error during the metadata fetching the
/// manager will ask its delegate to present an alert suggesting the user to try again, send a
/// feedback email or abort the operation. The signal will err if the user choses to cancel the
/// operation or after feedback mail composition has completed.
///
/// @note All events are delivered on the main thread.
- (RACSignal<BZRReceiptSubscriptionInfo *> *)purchaseSubscription:(NSString *)productIdentifier;

/// Restores previous user purchases. It also takes care of displaying failure alert, giving the
/// user the option to try again, send a feedback email or abort the operation.
///
/// Returns a signal that restore purchases on subscription. If restoration has completed
/// successfully the signal will deliver a single \c BZRReceiptInfo value describing user's
/// active subscription and other in-app purchased he made and then complete. If the request was
/// actively cancelled the signal will complete without sending any value. If there was an error
/// during the metadata fetching the manager will ask its delegate to present an alert suggesting
/// the user to try again, send a feedback email or abort the operation. The signal will err if the
/// user choses to cancel the operation or after feedback mail composition has completed.
///
/// @note All events are delivered on the main thread.
- (RACSignal<BZRReceiptInfo *> *)restorePurchases;

#pragma mark -
#pragma mark Delegate Replacement
#pragma mark -

/// Hot signal that delivers an \c SPXAlertViewModel whenever the manager asks his delegate to
/// present an alert. Subscribers should present an alert in response, and activate the action
/// attached with the alert button that user pressed. The signal completes when the manager is
/// dellocated.
///
/// It is recommended to subscribe to this signal before initating any other operation on the
/// manager. Failing to it this way may lead requests getting lost.
///
/// @note Values are delivered on the main thread.
@property (readonly, nonatomic) RACSignal<id<SPXAlertViewModel>> *alertRequested;

/// Hot signal that delivers an \c LTVoidBlock whenever the manager asks his delegate to present the
/// feedback mail composer. Subscribers should present a mail composer in response, and invoke the
/// completion block when mail composer has dismissed. The signal completes when the manager is
/// dellocated.
///
/// It is recommended to subscribe to this signal before initating any other operation on the
/// manager. Failing to it this way may lead to requests getting lost.
///
/// @note Values are delivered on the main thread.
@property (readonly, nonatomic) RACSignal<LTVoidBlock> *feedbackMailComposerRequested;

@end

NS_ASSUME_NONNULL_END
