// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBLibraryLoader.h"

NS_ASSUME_NONNULL_BEGIN

id<MTLLibrary> MTBLoadLibrary(id<MTLDevice> device, NSString *path) {
  typedef NSMutableDictionary<NSString *, id<MTLLibrary>> PNKDictionaryStringToLibrary;
  typedef NSMapTable<id<MTLDevice>, PNKDictionaryStringToLibrary *> PNKMapTableDeviceToDictionary;
  static auto deviceToDictionary = [PNKMapTableDeviceToDictionary
                                    mapTableWithKeyOptions:NSMapTableWeakMemory |
                                                           NSMapTableObjectPointerPersonality
                                    valueOptions:NSMapTableStrongMemory];
  static auto lock = [[NSLock alloc] init];
  [lock lock];

  PNKDictionaryStringToLibrary * _Nullable pathToLibrary = [deviceToDictionary objectForKey:device];
  if (!pathToLibrary) {
    pathToLibrary = [PNKDictionaryStringToLibrary dictionary];
    [deviceToDictionary setObject:pathToLibrary forKey:device];
  }

  auto _Nullable library = pathToLibrary[path];
  if (!library) {
    NSError *error;
    library = [device newLibraryWithFile:path error:&error];
    if (!library) {
      [lock unlock];
      LTParameterAssert(NO, @"Could not create library from path %@. Error: %@", path, error);
    }

    pathToLibrary[path] = library;
  }

  [lock unlock];
  return nn(library);
}

NS_ASSUME_NONNULL_END
