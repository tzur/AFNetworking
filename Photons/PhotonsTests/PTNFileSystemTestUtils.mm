// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemTestUtils.h"

#import <LTKit/LTPath.h>

#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFileDescriptor.h"

PTNFileSystemFileDescriptor *PTNFileSystemFileFromString(NSString *path) {
  return [[PTNFileSystemFileDescriptor alloc] initWithPath:[LTPath pathWithPath:path]];
}

PTNFileSystemFileDescriptor *PTNFileSystemFileFromFileURL(NSURL *url) {
  return [[PTNFileSystemFileDescriptor alloc] initWithPath:[LTPath pathWithFileURL:url]];
}

PTNFileSystemDirectoryDescriptor *PTNFileSystemDirectoryFromString(NSString *path) {
  return [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:[LTPath pathWithPath:path]];
}

PTNFileSystemDirectoryDescriptor *PTNFileSystemDirectoryFromString(NSURL *url) {
  return [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:[LTPath pathWithFileURL:url]];
}
