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

@end

NS_ASSUME_NONNULL_END
