// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

/// Asynchronous provider of help documents, as \c HUIDocument objects.
///
/// The documents are loaded from JSON files, named <tt>Help<Name>.json</tt>, where <tt><Name></tt>
/// is the document's name.
@interface HUIDocumentProvider : NSObject

/// Initializes with the main bundle as the location of help documents.
- (instancetype)init;

/// Initializes with \c baseURL as a file URL of a directory where JSON files of help documents are
/// stored.
- (instancetype)initWithBaseURL:(NSURL *)baseURL NS_DESIGNATED_INITIALIZER;

/// Returns a signal of \c HUIDocument that loads and sends the help document that is associated
/// with the first component of the given \c featureHierarchyPath that has a document assocciated
/// with it, and completes afterwards. The signal erros if the help document cannot be
/// provided. Lifetime of the returned signal is not affected by the lifetime of the provider.
///
/// The \c featureHierarchyPath is the feature-tree path to a node. For example
/// "Filters/Clip/EnlightVideo", in which a JSON file name <tt>HelpFilters.json</tt> will be
/// searched for (followed by <tt>HelpClip.json</tt> etc.), and if found, its corresponding help
/// document will be returned.
///
/// @note the signal might be delivered on any scheduler.
///
/// @note be careful when ignoring errors sent by the signal, since it can lead to actual
/// programming errors staying under the surface. For example, a typo in url's name causes an
/// error, and if ignored it may stay unnoticed for a long time.
- (RACSignal *)helpDocumentFromPath:(NSString *)featureHierarchyPath;

@end

NS_ASSUME_NONNULL_END
