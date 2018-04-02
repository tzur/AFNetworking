// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVPlayerItem.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <Photons/PTNAVAssetFetchOptions.h>
#import <Photons/PTNAlbum.h>
#import <Photons/PTNAlbumChangeset.h>
#import <Photons/PTNAssetManager.h>
#import <Photons/PTNDescriptor.h>
#import <Photons/PTNImageAsset.h>
#import <Photons/PTNImageFetchOptions.h>
#import <Photons/PTNProgress.h>
#import <Photons/PTNResizingStrategy.h>
#import <Photons/RACSignal+Photons.h>

#import "PTUTimeFormatter.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kPTUImageCellViewModelTraitSessionKey = @"Session";
NSString * const kPTUImageCellViewModelTraitCloudBasedKey = @"Cloud";
NSString * const kPTUImageCellViewModelTraitVideoKey = @"Video";
NSString * const kPTUImageCellViewModelTraitRawKey = @"Raw";
NSString * const kPTUImageCellViewModelTraitGIFKey = @"GIF";

@interface PTUImageCellViewModel ()

/// Time formatter for the duration of video assets.
@property (readonly, nonatomic) id<PTUTimeFormatter> timeFormatter;

@end

@implementation PTUImageCellViewModel

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                          descriptor:(id<PTNDescriptor>)descriptor
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions {
  return [self initWithAssetManager:assetManager descriptor:descriptor
                  imageFetchOptions:imageFetchOptions
                      timeFormatter:[[PTUTimeFormatter alloc] init]];
}

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                          descriptor:(id<PTNDescriptor>)descriptor
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions
                       timeFormatter:(id<PTUTimeFormatter>)timeFormatter {
  if (self = [super init]) {
    _assetManager = assetManager;
    _descriptor = descriptor;
    _imageFetchOptions = imageFetchOptions;
    _timeFormatter = timeFormatter;
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
      ptn_image]
      deliverOnMainThread];
}

- (nullable RACSignal<AVPlayerItem *> *)playerItemSignal {
  if (![self.traits containsObject:kPTUImageCellViewModelTraitVideoKey]) {
    return nil;
  }

  PTNAVAssetFetchOptions *options =
      [PTNAVAssetFetchOptions optionsWithDeliveryMode:PTNAVAssetDeliveryModeAutomatic];
  return [[[self.assetManager fetchAVPreviewWithDescriptor:self.descriptor options:options]
      ptn_skipProgress]
      deliverOnMainThread];
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

- (nullable RACSignal *)durationSignal {
  if ([self.traits containsObject:kPTUImageCellViewModelTraitVideoKey]) {
    return [self videoDuartionString];
  }
  return nil;
}

- (NSString *)stringWithImageCount:(NSUInteger)count {
  return [NSString stringWithFormat:_LPlural(@"%lu Photos", @"Label under a photo album name, "
                                             "describing the number of photos currently present in "
                                             "that album"), count];
}

- (nullable RACSignal *)videoDuartionString {
  if (![self.descriptor.class conformsToProtocol:@protocol(PTNAssetDescriptor)]) {
    LogError(@"Request video duration string for improper descriptor: %@", self.descriptor);
    return nil;
  }
  id<PTNAssetDescriptor> descriptor = (id<PTNAssetDescriptor>)self.descriptor;
  return [RACSignal return:[self.timeFormatter timeStringForTimeInterval:descriptor.duration]];
}

- (NSSet *)traits {
  NSMutableSet *traits = [NSMutableSet set];
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitSessionKey]) {
    [traits addObject:kPTUImageCellViewModelTraitSessionKey];
  }
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitCloudBasedKey]) {
    [traits addObject:kPTUImageCellViewModelTraitCloudBasedKey];
  }
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitAudiovisualKey]) {
    [traits addObject:kPTUImageCellViewModelTraitVideoKey];
  }
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitRawKey]) {
    [traits addObject:kPTUImageCellViewModelTraitRawKey];
  }
  if ([self.descriptor.descriptorTraits containsObject:kPTNDescriptorTraitGIFKey]) {
    [traits addObject:kPTUImageCellViewModelTraitGIFKey];
  }
  return traits;
}

@end

NS_ASSUME_NONNULL_END
