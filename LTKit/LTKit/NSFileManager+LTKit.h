// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Groups various file operations in order to provide another level of dereference for easy
/// testing and mocking.
@interface NSFileManager (LTKit)

/// Path to the documents directory of the app.
+ (NSString *)lt_documentsDirectory;

/// Path to the discardable caches directory of the app.
+ (NSString *)lt_cachesDirectory;

/// Path to the application support directory of the app.
+ (NSString *)lt_applicationSupportDirectory;

/// Returns \c YES if a file exists at the given \c path.
- (BOOL)lt_fileExistsAtPath:(NSString *)path;

/// Returns \c YES if a directory exists at the given \c path.
- (BOOL)lt_directoryExistsAtPath:(NSString *)path;

/// Writes the given dictionary to the file specified by the given path. Returns \c YES if the file
/// is written successfully, otherwise returns \c NO and populates \c error. The plist is saved in
/// the given \c format, and the file is written atomically.
///
/// This method recursively validates that all the contained objects are property list objects
/// (instances of \c NSData, \c NSDate, \c NSNumber, \c NSString, \c NSArray, or \c NSDictionary)
/// before writing out the file, and returns \c NO if all the objects are not property list objects,
/// since the resultant file would not be a valid property list.
- (BOOL)lt_writeDictionary:(NSDictionary *)dictionary toFile:(NSString *)path
                    format:(NSPropertyListFormat)format error:(NSError **)error;

/// Writes the given dictionary to the file specified by the given path. Returns \c YES if the file
/// is written successfully, otherwise returns \c NO and populates \c error. The plist is saved in
/// the XML property list format (\c NSPropertyListXMLFormat_v1_0), and the file is written
/// atomically.
///
/// This method recursively validates that all the contained objects are property list objects
/// (instances of \c NSData, \c NSDate, \c NSNumber, \c NSString, \c NSArray, or \c NSDictionary)
/// before writing out the file, and returns \c NO if all the objects are not property list objects,
/// since the resultant file would not be a valid property list.
- (BOOL)lt_writeDictionary:(NSDictionary *)dictionary toFile:(NSString *)path
                     error:(NSError **)error;

/// Creates and returns a dictionary using the keys and values found in a file specified by a given
/// path, or \c nil while populating \c error if there is a file error or if the contents of the
/// file are an invalid representation of a dictionary.
- (nullable NSDictionary *)lt_dictionaryWithContentsOfFile:(NSString *)path error:(NSError **)error;

/// Writes the bytes in the receiver to the file specified by a given path.
///
/// @param data Data to write.
/// @param path Location to which to write the receiver's bytes.
/// @param options Mask that specifies options for writing the data.
/// @param error If there is an error writing out the data, upon return contains an NSError object
/// that describes the problem.
- (BOOL)lt_writeData:(NSData *)data toFile:(NSString *)path options:(NSDataWritingOptions)options
               error:(NSError **)error;

/// Creates and returns a data object by reading every byte from the file specified by a given path,
/// or \c nil if an error occurred.
///
/// @param path Absolute path of the file from which to read data.
/// @param mask Mask that specifies options for reading the data.
/// @param error If an error occurs, upon return contains an NSError object that describes the
/// problem.
- (nullable NSData *)lt_dataWithContentsOfFile:(NSString *)path
                                       options:(NSDataReadingOptions)options
                                         error:(NSError **)error;

/// Globs the given \c path with optional \c recursion, returning paths of files that match the
/// given \c predicate (for \c NSString paths). If an error has occurred, the returned array will be
/// \c nil and the \c error will be populated.
///
/// @note returned paths are relative to the given \c path, and are not absolute paths.
- (nullable NSArray<NSString *> *)lt_globPath:(NSString *)path recursively:(BOOL)recursively
                                withPredicate:(NSPredicate *)predicate error:(NSError **)error;

/// Sets the given file URL to skip iCloud and iTunes backups or not. \c url must be a file URL.
/// Returns \c YES if the attribute setup completed successfully, otherwise returns \c NO and
/// populates the given \c error.
- (BOOL)lt_skipBackup:(BOOL)skipBackup forItemAtURL:(NSURL *)url error:(NSError **)error;

/// Returns the size of all files in in directory at the given \c path. The returned value is the
/// accumulated size of all files in the directory and all of its subdirectories. In case of an
/// error in reading the size of any file, \c error will be populated and the returned size will be
/// the sum of successfully read files sizes. In case the given \c path does not lead to a directory
/// the returned value will be \c 0 and \c error will be populated.
///
/// @note The size of a file with multiple hard links will be counted once.
///
/// @note The size of symbolic links will only be the size of the link, not the size of the file
/// they link to.
- (uint64_t)lt_sizeOfDirectoryAtPath:(NSURL *)path error:(NSError **)error;

/// Total storage (in bytes) on the device. This property is not KVO compliant.
@property (readonly, nonatomic) uint64_t lt_totalStorage;

/// Free storage (in bytes) on the device. This property is not KVO compliant.
@property (readonly, nonatomic) uint64_t lt_freeStorage;

@end

NS_ASSUME_NONNULL_END
