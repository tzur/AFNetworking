// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

#import <LTKit/LTRandomAccessCollection.h>
#import <Photons/PTNAlbum.h>
#import <Photons/PTNAlbumChangeset.h>
#import <Photons/PTNAssetManager.h>
#import <Photons/PTNDescriptor.h>
#import <Photons/PTNImageAsset.h>
#import <Photons/PTNImageFetchOptions.h>
#import <Photons/PTNProgress.h>
#import <Photons/PTNResizingStrategy.h>

NS_ASSUME_NONNULL_BEGIN

NSString * const kPTUImageCellViewModelTraitSessionKey = @"Session";
NSString * const kPTUImageCellViewModelTraitCloudBasedKey = @"Cloud";
NSString * const kPTUImageCellViewModelTraitVideoKey = @"Video";

@implementation PTUImageCellViewModel

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                          descriptor:(id<PTNDescriptor>)descriptor
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions {
  if (self = [super init]) {
    _assetManager = assetManager;
    _descriptor = descriptor;
    _imageFetchOptions = imageFetchOptions;
  }
  return self;
}

#pragma mark -
#pragma mark PTUImageCellViewModel
#pragma mark -

- (nullable RACSignal *)imageSignalForCellSize:(CGSize)cellSize {
  return [[[self.assetManager fetchImageWithDescriptor:self.descriptor
                                      resizingStrategy:[PTNResizingStrategy aspectFill:cellSize]
                                               options:self.imageFetchOptions]
      filter:^BOOL(PTNProgress *progress) {
        return progress.result != nil;
      }]
      flattenMap:^(PTNProgress<id<PTNImageAsset>> *progress) {
        return [progress.result fetchImage];
      }];
}

- (nullable RACSignal *)titleSignal {
  return [RACSignal return:self.descriptor.localizedTitle];
}

- (nullable RACSignal *)subtitleSignal {
  if ([self.descriptor conformsToProtocol:@protocol(PTNAlbumDescriptor)]) {
    id<PTNAlbumDescriptor> albumDescriptor = (id<PTNAlbumDescriptor>)self.descriptor;
    if (albumDescriptor.assetCount != PTNNotFound) {
      return [RACSignal return:[self stringWithImageCount:albumDescriptor.assetCount]];
    }

    return [[self.assetManager fetchAlbumWithURL:self.descriptor.ptn_identifier]
        map:^NSString *(PTNAlbumChangeset *changeset) {
          return [self stringWithImageCount:changeset.afterAlbum.assets.count];
        }];
  }

  return nil;
}

- (NSString *)stringWithImageCount:(NSUInteger)count {
  return [NSString stringWithFormat:_LPlural(@"%lu Photos", @"Label under a photo album name, "
                                             "describing the number of photos currently present in "
                                             "that album"), count];
}

- (NSSet *)traits {
  NSMutableSet *traits = [NSMutableSet set];
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitSessionKey]) {
    [traits addObject:kPTUImageCellViewModelTraitSessionKey];
  }
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitCloudBasedKey]) {
    [traits addObject:kPTUImageCellViewModelTraitCloudBasedKey];
  }
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitVideoKey]) {
    [traits addObject:kPTUImageCellViewModelTraitVideoKey];
  }
  return traits;
}

@end

NS_ASSUME_NONNULL_END
