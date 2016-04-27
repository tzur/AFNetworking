// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Category for operators on signals that send \c BLUNode objects on them.
@interface RACSignal (BLUNode)

/// Returns the subtree that begins at the given \c path. Thus, the \c BLUNode returned from this
/// operator will be the node located at \c path. Any updates to the input tree under \c path will
/// produce a new value that will be sent over \c path.
///
/// The signal will complete when the receiver completes and will err with
/// \c BLUErrorCodePathNotFound if \c path is not valid.
///
/// @note The receiver must carry only \c BLUNode objects.
- (RACSignal *)blu_subtreeAtPath:(NSString *)path;

/// Returns a signal that adds child nodes, provided by \c signal, to the end of the child nodes
/// collection of the node at the given \c path. \c signal must carry an \c NSArray of \c BLUNode
/// objects.
///
/// If a value is sent on the receiver before \c signal sends childs node to add, the value will be
/// passed through in the returned signal (i.e. it will not wait like in \c combineLatest:).
///
/// The signal will complete when both the receiver and \c signal completes. If \c path is no longer
/// valid, the signal will err with \c BLUErrorCodePathNotFound.
///
/// @note The receiver must carry only \c BLUNode objects.
- (RACSignal *)blu_addChildNodes:(RACSignal *)signal toPath:(NSString *)path;

/// Returns a signal that inserts child nodes, provided by \c signal, to the given indexes in the
/// child nodes collection of the node at the given \c path. \c signal must carry tuples of
/// <tt>(NSArray<BLUNode *> *, NSIndexSet *)</tt>.
///
/// If a value is sent on the receiver before \c signal sends childs node to add, the value will be
/// passed through in the returned signal (i.e. it will not wait like in \c combineLatest:).
///
/// The signal will complete when both the receiver and \c signal completes. If \c path is no longer
/// valid, the signal will err with \c BLUErrorCodePathNotFound.
///
/// @note The receiver must carry only \c BLUNode objects.
- (RACSignal *)blu_insertChildNodes:(RACSignal *)signal toPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
