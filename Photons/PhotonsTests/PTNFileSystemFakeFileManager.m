// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemFakeFileManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemFakeFileManagerFile ()

/// Fake file's name.
@property (strong, nonatomic) NSString *name;

/// Fake files's path upto and not including its name.
@property (strong, nonatomic) NSString *path;

/// \c YES if this file represents a directory.
@property (nonatomic) BOOL isDirectory;

@end

@implementation PTNFileSystemFakeFileManagerFile

- (instancetype)initWithName:(NSString *)name path:(NSString *)path isDirectory:(BOOL)isDirectory {
  if (self = [super init]) {
    self.name = name;
    self.path = path;
    self.isDirectory = isDirectory;
  }
  return self;
}

@end

/// Fake file resource URL enabling setting and getting resource values without an underlying file
/// system object.
@interface PTNFakeFileResourceURL : NSURL

/// Dictionary of resources to set and get instead of file system file metadata.
@property (strong, nonatomic) NSDictionary *resources;

@end

@implementation PTNFakeFileResourceURL

- (BOOL)getResourceValue:(out id _Nullable __autoreleasing *)value forKey:(NSString *)key
                   error:(out NSError * _Nullable __unused __autoreleasing *)error {
  *value = self.resources[key];
  return self.resources[key] != nil;
}

@end

@implementation PTNFileSystemFakeFileManager

- (instancetype)initWithFiles:(NSArray<PTNFileSystemFakeFileManagerFile *> *)files {
  if (self = [self init]) {
    self.files = files;
  }
  return self;
}

- (nullable PTNFileSystemFakeFileManagerFile *)fileAtPath:(NSString *)path {
  for (PTNFileSystemFakeFileManagerFile *file in self.files) {
    if ([[file.path stringByAppendingPathComponent:file.name] isEqualToString:path]) {
      return file;
    }
  }
  return nil;
}

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(nullable BOOL *)isDirectory {
  PTNFileSystemFakeFileManagerFile *file = [self fileAtPath:path];
  if (isDirectory) {
    *isDirectory = file.isDirectory;
  }
  return file != nil;
}

- (nullable NSArray<NSURL *> *)contentsOfDirectoryAtURL:(NSURL *)url
    includingPropertiesForKeys:(nullable __unused NSArray<NSString *> *)keys
    options:(__unused NSDirectoryEnumerationOptions)mask
    error:(NSError *_Nullable __autoreleasing *)error {
  NSString *path = url.relativePath ?: @"/";
  PTNFileSystemFakeFileManagerFile *directory = [self fileAtPath:path];
  if (!directory.isDirectory) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound path:path];
    }
  }

  return [[self.files.rac_sequence
      filter:^BOOL(PTNFileSystemFakeFileManagerFile *file) {
        return [file.path isEqualToString:path];
      }]
      map:^id(PTNFileSystemFakeFileManagerFile *file) {
        NSString *filePath = [path stringByAppendingPathComponent:file.name];
        PTNFakeFileResourceURL *fileURL = [[PTNFakeFileResourceURL alloc]
                                           initFileURLWithPath:filePath];
        if ([[self videoExtensions] containsObject:filePath.pathExtension.lowercaseString]) {
          fileURL.resources = @{
            NSURLNameKey: file.name,
            NSURLIsDirectoryKey: @(file.isDirectory),
            NSURLTypeIdentifierKey: @"public.mpeg-4"
          };
        } else if ([[self imageExtensions] containsObject:filePath.pathExtension.lowercaseString]) {
          fileURL.resources = @{
            NSURLNameKey: file.name,
            NSURLIsDirectoryKey: @(file.isDirectory),
            NSURLTypeIdentifierKey: @"public.jpeg"
          };
        } else {
          fileURL.resources = @{
            NSURLNameKey: file.name,
            NSURLIsDirectoryKey: @(file.isDirectory)
          };
        }
        return fileURL;
      }].array;
}

- (NSArray<NSString *> *)videoExtensions {
  return @[@"mp4", @"qt", @"m4v", @"mov"];
}

- (NSArray<NSString *> *)imageExtensions {
  return @[@"jpg", @"jpeg", @"tiff", @"png"];
}

@end

NS_ASSUME_NONNULL_END
