// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class PTNImageMetadata;

@interface RACSignal<__covariant ValueType> (Photons)

/// Multicasts the signal to a \c RACReplaySubject of capacity 1, and lazily connects to the
/// resulting \c RACMulticastConnection.
///
/// This means the returned signal will subscribe to the multicasted signal only when the former
/// receives its first subscription.
///
/// Returns the lazily connected, multicasted signal.
- (RACSignal<ValueType> *)ptn_replayLastLazily;

/// Catches errors sent by the receiver and maps them to \c error with the original error as its
/// underlying error. If \c error already has an underlying error, it will be overwritten.
///
/// @note Underlying error is stored in the error's \c userInfo property under the
/// \c NSUnderlyingErrorKey key.
- (RACSignal<ValueType> *)ptn_wrapErrorWithError:(NSError *)error;

/// Combines the latest values from each of the given \c signals by sending the latest value from
/// each signal accompanied with the index of the signal that caused a new value to be sent over the
/// receiver. For the returned signal to send an initial value, all the \c signals must send at
/// least one value. The initially sent value will send a \c nil index.
///
/// If \c signals is empty, the returned signal will immediately complete upon subscription.
///
/// Returns a signal in the format <tt>((v_0, v_1, ..., v_n), index)</tt>, where
/// <tt>{v_0, v_1, ..., v_n}</tt> are the latest values from the given \c signals and \c index is
/// the index in the range <tt>{0, 1, ..., n}</tt> of the latest signal that caused a new value to
/// be sent over the receiver. The returned signal forwards any \c error events, and completes when
/// all input signals complete.
+ (RACSignal<RACTuple *> *)ptn_combineLatestWithIndex:(id<NSFastEnumeration>)signals;

/// Skips incomplete progress values and combines the latest image and image metadata signals of
/// completed progress objects.
///
/// The receiver is assumed to send a sequence of zero or more \c PTNProgress<id<PTNImageAsset>>
/// values followed by one or more completed \c PTNProgress<id<PTNImageAsset>> values.
///
/// The returned signal sends a \c RACTuple of <tt>(UIImage, PTNImageMetadata)</tt> pairs for each
/// completed \c PTNProgress object, by combining the latest image and image metadata fetching
/// signals of the \c id<PTNImageAsset> \c result. It completes when the receiver completes before
/// sending a completed \c PTNProgress or when the receiver, the image fetching signal and the image
/// metadata fetching signal complete. It errs when the receiver, the image fetching signal or the
/// image metadata fetching signal errs.
- (RACSignal<RACTwoTuple<UIImage *, PTNImageMetadata *> *> *)ptn_imageAndMetadata;

/// Skips incomplete progress values and flattens image signal of completed progress objects.
///
/// The receiver is assumed to send a sequence of zero or more \c PTNProgress<id<PTNImageAsset>>
/// values followed by one or more completed \c PTNProgress<id<PTNImageAsset>> values.
///
/// The returned signal sends a \c UIImage for each completed \c PTNProgress object, by flattening
/// the image fetching signal of the \c id<PTNImageAsset> \c result. It completes when the receiver
/// completes before sending a completed \c PTNProgress or when both the receiver and the image
/// fetching signal complete. It errs when the receiver or the image fetching signal errs.
- (RACSignal<UIImage *> *)ptn_image;

/// Skips incomplete progress values.
///
/// The receiver is assumed to send a sequence of zero or more \c PTNProgress values followed by one
/// or more completed \c PTNProgress values.
///
/// The returned signal sends the \c result value for each completed \c PTNProgress sent by
/// the receiver. It completes or errs when the receiver completes or errs respectively.
- (RACSignal *)ptn_skipProgress;

@end

NS_ASSUME_NONNULL_END
