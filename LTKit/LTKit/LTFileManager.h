// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Groups various file operations in order to provide another level of dereference for easy
/// testing and mocking.
@interface LTFileManager : NSObject

/// Path to the documents directory of the app.
+ (NSString *)documentsDirectory;

/// Writes the bytes in the receiver to the file specified by a given path.
///
/// @param data Data to write.
/// @param path Location to which to write the receiver's bytes.
/// @param options Mask that specifies options for writing the data.
/// @param error If there is an error writing out the data, upon return contains an NSError object
/// that describes the problem.
- (BOOL)writeData:(NSData *)data toFile:(NSString *)path options:(NSDataWritingOptions)options
            error:(NSError **)error;

/// Creates and returns a data object by reading every byte from the file specified by a given path.
///
/// @param path Absolute path of the file from which to read data.
/// @param mask Mask that specifies options for reading the data.
/// @param error If an error occurs, upon return contains an NSError object that describes the
/// problem.
- (NSData *)dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)options
                             error:(NSError **)error;

/// Globs the given \c path with optional \c recursion, returning paths of files that match the
/// given \c predicate (for \c NSString paths). If an error has occurred, the returned array will be
/// \c nil and the \c error will be populated.
///
/// @note returned paths are relative to the given \c path, and are not absolute paths.
- (NSArray *)globPath:(NSString *)path recursively:(BOOL)recursively
        withPredicate:(NSPredicate *)predicate error:(NSError **)error;

@end
