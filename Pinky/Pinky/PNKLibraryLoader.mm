// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKLibraryLoader.h"

#import "NSBundle+PinkyBundle.h"

NS_ASSUME_NONNULL_BEGIN

id<MTLLibrary> PNKLoadLibrary(id<MTLDevice> device) {
  static auto mapTable =
      [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                            valueOptions:NSMapTableStrongMemory];
  static auto lock = [[NSLock alloc] init];
  [lock lock];

  id<MTLLibrary> _Nullable library = [mapTable objectForKey:device];
  if (library) {
    [lock unlock];
    return library;
  }

  NSBundle * _Nullable bundle = [NSBundle pnk_bundle];
  LTAssert(bundle, @"Could not find Pinky bundle in the main bundle of the app");
  auto _Nullable metalPath = [bundle pathForResource:@"default" ofType:@"metallib"];
  LTAssert(metalPath, @"Could not find metallib resource in Pinky bundle");

  NSError *error;
  library = [device newLibraryWithFile:metalPath error:&error];
  LTAssert(library, @"Could not create MTLLibrary from path %@. Error: %@", metalPath, error);
  [mapTable setObject:library forKey:device];
  [lock unlock];
  return library;
}

NS_ASSUME_NONNULL_END
