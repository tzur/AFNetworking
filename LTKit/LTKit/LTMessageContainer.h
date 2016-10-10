// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

NS_ASSUME_NONNULL_BEGIN

/// Container that saves messages for future access. The container must be thread safe.
@protocol LTMessageContainer <NSObject>

/// Adds the given \c message to the container.
- (void)addMessage:(NSString *)message;

/// Combined log of the saved log lines in the repository. Entries will be separated by a newline
/// character.
@property (readonly, nonatomic) NSString *messageLog;

/// The messages that are currently stored.
@property (readonly, nonatomic) NSArray<NSString *> *messages;

@end

NS_ASSUME_NONNULL_END
