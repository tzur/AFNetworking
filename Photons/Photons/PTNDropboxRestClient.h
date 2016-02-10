// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class PTNDropboxThumbnailType;

@protocol PTNDropboxPathProvider, PTNDropboxRestClientProvider;

NS_ASSUME_NONNULL_BEGIN

/// Wrapper to a linked Dropbox REST client.
@interface PTNDropboxRestClient : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes an with a \c restClientProvider and \c pathProvider. \c restClientProvider supplies
/// Dropbox REST clients. \c pathProvider is used to supply file paths in which to save downloaded
/// assets.
- (instancetype)initWithRestClientProvider:(id<PTNDropboxRestClientProvider>)restClientProvider
                              pathProvider:(id<PTNDropboxPathProvider>)pathProvider
    NS_DESIGNATED_INITIALIZER;

/// Fetches the \c DBMetadata located at \c path relative to the Dropbox session's root folder, in
/// given \c revision. The returned signal will send a \c DBMetadata object on an arbitrary thread,
/// completes after the result is sent and errs if an error occurred while fetching the metadata.
/// The result type will always be a \c DBMetadata. If the asset doesn't exist, the signal will err.
/// If the given \c revision is \c nil, the fetched metadata refers to the latest revision of the
/// file represented by \c path.
///
/// @note This request is not cancelable.
///
/// @note This is a cold signal and every subscription creates a new REST client and issues a fetch
/// request to it.
///
/// @return <tt>RACSignal<DBMetadata></tt>.
- (RACSignal *)fetchMetadata:(NSString *)path revision:(nullable NSString *)revision;

/// Fetches the contents of file located at \c path relative to the Dropbox session's root folder,
/// in given \c revision. The returned signal will send a \c PTNProgress object on an arbitrary
/// thread, completes after the final result is sent and errs if an error occurred while fetching
/// the file. The result type will always be an \c NSString representing the local path in which it
/// file was saved. If the asset doesn't exist, the signal will err. Disposal of the returned
/// signal's subscription will abort the current fetch operation, if in progress. If the given
/// \c revision is \c nil, the fetched file refers to the latest revision of the file represented by
/// \c path.
///
/// @note This is a cold signal and every subscription creates a new REST client and issues a fetch
/// request to it.
///
/// @return <tt>RACSignal<PTNProgress<NSString *>></tt>.
- (RACSignal *)fetchFile:(NSString *)path revision:(nullable NSString *)revision;

/// Fetches the thumbnail of type \c type for Dropbox entry located at \c path relative to the
/// Dropbox session's root folder. The returned signal will send an \c NSString object on an
/// arbitrary thread, completes after result is sent and errs if an error occurred while fetching
/// the thumbnail. The result type will always be an \c NSString representing the local path in
/// which it thumbnail was saved. If asset doesn't exist, the signal will err. Disposal of the
/// returned signal's subscription will abort the current fetch operation, if in progress.
///
/// @note This is a cold signal and every subscription creates a new REST client and issues a fetch
/// request to it.
///
/// @return <tt>RACSignal<NSString *></tt>.
- (RACSignal *)fetchThumbnail:(NSString *)path type:(PTNDropboxThumbnailType *)type;

@end

NS_ASSUME_NONNULL_END
