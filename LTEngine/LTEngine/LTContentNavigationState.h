// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Value class constituting the state of an \c id<LTContentNavigationManager>. Appropriate
/// subclasses of this class should be used by objects implementing the
/// \c LTContentNavigationManager protocol, in order to save their current navigation state.
@interface LTContentNavigationState : NSObject
@end

NS_ASSUME_NONNULL_END
