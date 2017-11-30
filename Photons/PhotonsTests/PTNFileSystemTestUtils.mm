// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNFileSystemTestUtils.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSBundle+Path.h>

#import "PTNFileSystemDirectoryDescriptor.h"
#import "PTNFileSystemFileDescriptor.h"

/// Class that resides in the test bundle of Photons.
@interface PTNClassInTestBundle : NSObject
@end

@implementation PTNClassInTestBundle
@end

LTPath *PTNFileSystemPathFromString(NSString *path) {
  return [LTPath pathWithBaseDirectory:LTPathBaseDirectoryNone andRelativePath:path];
}

PTNFileSystemFileDescriptor *PTNFileSystemFileFromString(NSString *path) {
  return [[PTNFileSystemFileDescriptor alloc] initWithPath:PTNFileSystemPathFromString(path)];
}

PTNFileSystemDirectoryDescriptor *PTNFileSystemDirectoryFromString(NSString *path) {
  return [[PTNFileSystemDirectoryDescriptor alloc] initWithPath:PTNFileSystemPathFromString(path)];
}

NSURL *PTNOneSecondVideoPath() {
  NSString *path = [NSBundle lt_pathForResource:@"OneSecondVideo16x16.mp4"
                                      nearClass:PTNClassInTestBundle.class];
  return [NSURL fileURLWithPath:path];
}
