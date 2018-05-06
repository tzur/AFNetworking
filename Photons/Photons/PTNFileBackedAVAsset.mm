// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNFileBackedAVAsset.h"

#import <AVFoundation/AVAsset.h>
#import <LTKit/LTPath.h>
#import <LTKit/LTUTICache.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSErrorCodes+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileBackedAVAsset ()

/// The path to the file this class backs.
@property (readonly, nonatomic) LTPath *path;

@end

@implementation PTNFileBackedAVAsset

@synthesize uniformTypeIdentifier = _uniformTypeIdentifier;

- (instancetype)initWithFilePath:(LTPath *)path {
  if (self = [super init]) {
    _path = path;
    _uniformTypeIdentifier = path.url.pathExtension.length ?
        [LTUTICache.sharedCache preferredUTIForFileExtension:path.url.pathExtension] : nil;
  }
  return self;
}

- (RACSignal<NSData * > *)fetchData {
  return [[RACSignal defer:^RACSignal *{
    NSError *error;

    NSData *data = [NSData dataWithContentsOfFile:self.path.path options:NSDataReadingMappedIfSafe
                                           error:&error];
    if (!data) {
      return [RACSignal error:[NSError lt_errorWithCode:LTErrorCodeFileReadFailed
                                                    url:self.path.url
                                        underlyingError:error]];
    }

    return [RACSignal return:data];
  }]
  subscribeOn:RACScheduler.scheduler];
}

- (RACSignal *)writeToFileAtPath:(LTPath *)path usingFileManager:(NSFileManager *)fileManager {
  return [[RACSignal defer:^RACSignal *{
    NSError *error;
    BOOL success = [fileManager copyItemAtURL:self.path.url toURL:path.url error:&error];
    if (!success) {
      return [RACSignal error:[NSError lt_errorWithCode:LTErrorCodeFileWriteFailed
                                                    url:self.path.url
                                        underlyingError:error]];
    }

    return [RACSignal empty];
  }]
  subscribeOn:RACScheduler.scheduler];
}

- (RACSignal<AVAsset *> *)fetchAVAsset {
  return [RACSignal return:[AVAsset assetWithURL:self.path.url]];
}

@end

NS_ASSUME_NONNULL_END
