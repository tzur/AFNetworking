// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

@class TINMessage;

/// Category extending \c NSFileManager by adding an un/archive functionality of \c TINMessages.
@interface NSFileManager (TinCan)

/// Returns \c YES if the given \c message was securely coded and written to the given \c url
/// successfully. Otherwise \c NO is returned and the \c error is set. \c url must be file URL. It
/// will create all intermediate directories if they don't exist.
- (BOOL)tin_writeMessage:(TINMessage *)message toURL:(NSURL *)url error:(NSError **)error;

/// Returns \c TINMessage object from the given \c url. \c nil is returned and \c error is set if
/// an error occurred during this process. \c url must be a URL of a file.
- (nullable TINMessage *)tin_readMessageFromURL:(NSURL *)url error:(NSError **)error;

/// Removes all designated message directories for the given \c appGroupID and \c scheme. Returns
/// \c YES upon success, otherwise \c NO and sets the \c error.
///
/// @important user can safely remove only the message directories of messages which are targeted to
/// this application.
- (BOOL)tin_removeAllMessagesWithAppGroupID:(NSString *)appGroupID scheme:(NSString *)scheme
                                      error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
