// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Provides access to a subset of methods from the MobileCoreServices library.
@protocol LTMobileCoreServices <NSObject>

/// Returns \c YES if \c conformsToUTI is an ancestor of \c uti in the UTI hierarchy. For example,
/// the UTI "com.nikon.raw-image" conforms to "public.camera-raw-image". Note that any UTI conforms
/// to itself, i.e. "com.compuserve.gif" conforms to "com.compuserve.gif".
- (BOOL)isUTI:(NSString *)uti conformsTo:(NSString *)conformsToUTI;

/// Searches for all the matching uniform type identifiers that match the given \c fileExt. If
/// multiple UTIs match the given \c fileExt, the UTI that is returned is undefined.
///
/// If no result is found, this function creates a dynamic type beginning with the \c dyn prefix.
/// This UTI can be later used with the \c preferredFileExtensionForUTI: method to retrieve the
/// original file extension.
- (NSString *)preferredUTIForFileExtension:(NSString *)fileExt;

/// Searches for all the matching uniform type identifiers that match the given \c mimeType. If
/// multiple UTIs match the given \c mimeType, the UTI that is returned is undefined.
///
/// If no result is found, this function creates a dynamic type beginning with the \c dyn prefix.
/// This UTI can be later used with the \c preferredMIMETypeForUTI: method to retrieve the original
/// MIME type.
- (NSString *)preferredUTIForMIMEType:(NSString *)mimeType;

/// Searches for all the matching file extensions that match the given \c uti. If multiple file
/// extensions match the given \c uti, the first one is returned. \c nil is returned if no file
/// extension matches the given \c uti.
- (nullable NSString *)preferredFileExtensionForUTI:(NSString *)uti;

/// Searches for all the matching MIME types that match the given \c uti. If multiple MIME types
/// match the given \c uti, the first one is returned. \c nil is returned if no MIME type matches
/// the given \c uti.
- (nullable NSString *)preferredMIMETypeForUTI:(NSString *)uti;

@end

/// Default implementation. Calls the relevant methods from the MobileCoreServices framework.
@interface LTMobileCoreServices : NSObject <LTMobileCoreServices>
@end

/// Calls and caches values returned from \c LTMobileCoreServices methods. All the methods in this
/// class are thread-safe.
@interface LTUTICache : NSObject <LTMobileCoreServices>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c mobileCoreServices as the underlying UTI methods to cache.
- (instancetype)initWithMobileCoreServices:(id<LTMobileCoreServices>)mobileCoreServices
    NS_DESIGNATED_INITIALIZER;

/// The singleton object for this class. This instance is best used in order to share the cache
/// across the application.
@property (class, readonly, nonatomic) LTUTICache *sharedCache;

@end

NS_ASSUME_NONNULL_END
