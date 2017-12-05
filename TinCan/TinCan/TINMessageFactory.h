// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

@class TINMessage;

/// Available file operations.
LTEnumDeclare(NSUInteger, TINMessageFileOperation,
  /// File should be moved to a new location.
  TINMessageFileOperationMove,
  /// File should be copied to a new location.
  TINMessageFileOperationCopy
);

/// Implements convenience creation functionality of \c TINMessages. The created messages belong to
/// \c appGroupID application group ID. The \c fileManager is used to access the file system.
/// \c sourceScheme defines the scheme of the message sender application, which might be used by
/// the message recipient when replying.
@interface TINMessageFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c sourceScheme, which might be used by the message recipient when replying the
/// received message from this application. \c fileManager is initialized with the default
/// \c NSFileManager which is used to access the file system and \c appGroupID is set to
/// \c kTINAppGroupID.
+ (instancetype)messageFactoryWithSourceScheme:(NSString *)sourceScheme;

/// Initializes with the given \c sourceScheme which might be used by message recipient when
/// replying the received message and \c fileManager which is used to access the file system.
/// \c appGroupID is set to \c kTINAppGroupID.
+ (instancetype)messageFactoryWithSourceScheme:(NSString *)sourceScheme
                                   fileManager:(NSFileManager *)fileManager;

/// Initializes with the given \c sourceScheme which might be used by message recipient when
/// replying the received message and \c fileManager which is used to access the file system and
/// the given \c appGroupID which defines the application group ID the created messages be belong
/// to.
+ (instancetype)messageFactoryWithSourceScheme:(NSString *)sourceScheme
                                   fileManager:(NSFileManager *)fileManager
                                    appGroupID:(NSString *)appGroupID;

/// Block which provides a dictionary, of same type as \c TINMessage's \c userInfo, given the
/// \c messageDirectory. On error must return \c nil and optionally set the \c error. The returned
/// dictionary can be used to initialize \c userInfo in \c TINMessage. \c messageDirectory is \c nil
/// if the application doesn't have an entitlement to access the Application Group, in which case
/// the \c error is \c nil as well.
typedef NSDictionary<NSString *, id<NSSecureCoding>> * _Nullable
    (^TINMessageUserInfoProviderBlock)(NSURL *messageDirectory, NSError **error);

/// Returns \c TINMessage with the given \c targetScheme and \c block. Returns \c nil if error
/// occurs and sets the \c error. \c targetScheme is a scheme of an application which this message
/// is targeted to. \c block is invoked with a message designated directory URL and is expected to
/// return a dictionary which is used as \c userInfo when initializing the returned message.
///
/// @note the \c block isn't invoked when the application doesn't have an entitlement to access the
/// Application Group ID, in which case an appropriate \c error is set.
///
/// @note the \c block runs synchronously.
- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
                                           block:(TINMessageUserInfoProviderBlock)block
                                           error:(NSError **)error;

/// Returns a message with the given \c targetScheme, \c info, \c data and \c uti. Returns \c nil if
/// an error occurs and sets the \c error. \c targetScheme is a scheme of an application which this
/// message is targeted to. \c data is persistently stored in the message's associated directory and
/// can be obtained from the returned \c TINMessage \c fileName. The returned message's attached
/// \c fileName is suffixed with preferred extension for \c uti, which is returned by
/// \c UTTypeCreatePreferredIdentifierForTag() method.
- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
    userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info data:(NSData *)data
    uti:(NSString *)uti error:(NSError **)error;

/// Returns a message with the given \c targetScheme, \c info and \c image. Returns \c nil if an
/// error occurs and sets the \c error. \c targetScheme is a scheme of an application which this
/// message is targeted to. \c image is stored persistently, in lossless PNG format, in the
/// message's associated directory and can be obtained from the returned \c TINMessage \c fileName.
- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
    userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info image:(UIImage *)image
    error:(NSError **)error;

/// Returns a message with the given \c targetScheme, \c info, \c fileURL and \c operation. Returns
/// \c nil if an error occurs and sets the \c error. \c targetScheme is a scheme of an application
/// which this message is targeted to. A file referenced by \c fileURL is attached to the returned
/// message and stored persistently at message's designated directory. The file referenced by
/// \c fileURL is copied or moved to message's designated directory based on \c operation, while
/// preserving the file's path extension. Error is reported if \c fileURL references a directory or
/// non existing file.
- (nullable TINMessage *)messageWithTargetScheme:(NSString *)targetScheme
    userInfo:(NSDictionary<NSString *, id<NSSecureCoding>> *)info fileURL:(NSURL *)fileURL
    operation:(TINMessageFileOperation *)operation error:(NSError **)error;

/// File manager used to access the file system.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Scheme which is used as source scheme when creating the messages. It might be used by the
/// message recipient when replying the received message from this application.
@property (readonly, nonatomic) NSString *sourceScheme;

/// Application's group ID this factory is using when creating \c TINMessages.
@property (readonly, nonatomic) NSString *appGroupID;

@end

NS_ASSUME_NONNULL_END
