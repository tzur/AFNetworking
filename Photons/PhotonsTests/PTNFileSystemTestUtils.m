// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemTestUtils.h"

#import <LTKit/LTPath.h>

#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFileDescriptor.h"

LTPath *PTNFileSystemPathFromString(NSString *path) {
  return [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone andRelativePath:path];
}

PTNFileSystemFileDescriptor *PTNFileSystemFileFromString(NSString *path) {
  return [[PTNFileSystemFileDescriptor alloc] initWithPath:PTNFileSystemPathFromString(path)];
}

PTNFileSystemDirectoryDescriptor *PTNFileSystemDirectoryFromString(NSString *path) {
  return [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:PTNFileSystemPathFromString(path)];
}
