// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexerAssetManager.h"

#import "NSError+Photons.h"
#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNMultiplexerAssetManager

- (instancetype)initWithSources:(PTNSchemeToManagerMap *)mapping {
  if (self = [super init]) {
    _mapping = mapping;
  }
  return self;
}

#pragma mark -
#pragma mark Album fetching
#pragma mark -

- (RACSignal *)fetchAlbumWithURL:(NSURL *)url {
  id<PTNAssetManager> _Nullable assetManager = self.mapping[url.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme url:url]];
  }
  return [assetManager fetchAlbumWithURL:url];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  id<PTNAssetManager> _Nullable assetManager = self.mapping[url.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme url:url]];
  }
  return [assetManager fetchDescriptorWithURL:url];
}

#pragma mark -
#pragma mark Image fetching
#pragma mark -

- (RACSignal *)fetchImageWithDescriptor:(id<PTNDescriptor>)descriptor
                       resizingStrategy:(id<PTNResizingStrategy>)resizingStrategy
                                options:(PTNImageFetchOptions *)options {
  id<PTNAssetManager> _Nullable assetManager = self.mapping[descriptor.ptn_identifier.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                  associatedDescriptor:descriptor]];
  }
  return [assetManager fetchImageWithDescriptor:descriptor resizingStrategy:resizingStrategy
                                        options:options];
}

#pragma mark -
#pragma mark AVAsset fetching
#pragma mark -

- (RACSignal *)fetchAVAssetWithDescriptor:(id<PTNDescriptor>)descriptor
                                  options:(PTNAVAssetFetchOptions *)options {
  id<PTNAssetManager> _Nullable assetManager = self.mapping[descriptor.ptn_identifier.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                  associatedDescriptor:descriptor]];
  }
  return [assetManager fetchAVAssetWithDescriptor:descriptor options:options];
}

#pragma mark -
#pragma mark Image data fetching
#pragma mark -

- (RACSignal *)fetchImageDataWithDescriptor:(id<PTNDescriptor>)descriptor {
  id<PTNAssetManager> _Nullable assetManager = self.mapping[descriptor.ptn_identifier.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                  associatedDescriptor:descriptor]];
  }
  return [assetManager fetchImageDataWithDescriptor:descriptor];
}

#pragma mark -
#pragma mark AV preview fetching
#pragma mark -

- (RACSignal *)fetchAVPreviewWithDescriptor:(id<PTNDescriptor>)descriptor
                                    options:(PTNAVAssetFetchOptions __unused *)options {
  id<PTNAssetManager> _Nullable assetManager = self.mapping[descriptor.ptn_identifier.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                  associatedDescriptor:descriptor]];
  }
  return [assetManager fetchAVPreviewWithDescriptor:descriptor options:options];
}

#pragma mark -
#pragma mark Deletion
#pragma mark -

- (RACSignal *)deleteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors {
  NSArray *unsupportedDescriptors = [self unsupportedDescriptors:descriptors];
  if (unsupportedDescriptors.count) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                 associatedDescriptors:unsupportedDescriptors]];
  }

  NSDictionary<NSString *, NSArray<id<PTNDescriptor>> *> *schemeToDescriptors =
      [self schemeToDescriptors:descriptors];

  NSArray<RACSignal *> *deleteSignals = [schemeToDescriptors.allKeys.rac_sequence
      map:^RACSignal *(NSString *scheme) {
        return [self deleteDescriptors:schemeToDescriptors[scheme]
                           fromManager:self.mapping[scheme]];
      }].array;

  return [RACSignal merge:deleteSignals];
}

- (RACSignal *)deleteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                     fromManager:(id<PTNAssetManager>)manager {
  if (![manager respondsToSelector:@selector(deleteDescriptors:)]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                 associatedDescriptors:descriptors]];
  }

  return [manager deleteDescriptors:descriptors];
}

#pragma mark -
#pragma mark Removal
#pragma mark -

- (RACSignal *)removeDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                       fromAlbum:(id<PTNAlbumDescriptor>)albumDescriptor {
  NSString *albumScheme = albumDescriptor.ptn_identifier.scheme;
  NSDictionary<NSString *, NSArray *> *schemeToDescriptors = [self schemeToDescriptors:descriptors];

  id<PTNAssetManager> assetManager = self.mapping[albumScheme];
  if (!assetManager) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                  associatedDescriptor:albumDescriptor]];
  }

  if (![schemeToDescriptors[albumScheme] isEqual:descriptors]) {
    NSArray *invalidDescriptors = [[[schemeToDescriptors.allKeys.rac_sequence
        filter:^BOOL(NSString *scheme) {
          return ![scheme isEqualToString:albumScheme];
        }]
        map:^RACSequence *(NSString *scheme) {
          return schemeToDescriptors[scheme].rac_sequence;
        }]
        flatten].array;

    NSString *errorDescription = [NSString stringWithFormat:@"Given descriptors do not match album "
                                  "descriptor's scheme: %@", albumDescriptor];
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeAssetRemovalFromAlbumFailed
                                 associatedDescriptors:invalidDescriptors
                                           description:errorDescription]];
  }

  if (![assetManager respondsToSelector:@selector(removeDescriptors:fromAlbum:)]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                 associatedDescriptors:descriptors]];
  }

  return [assetManager removeDescriptors:descriptors fromAlbum:albumDescriptor];
}

#pragma mark -
#pragma mark Favorite
#pragma mark -

- (RACSignal *)favoriteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors
                          favorite:(BOOL)favorite {
  NSArray *unsupportedDescriptors = [self unsupportedDescriptors:descriptors];
  if (unsupportedDescriptors.count) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                 associatedDescriptors:unsupportedDescriptors]];
  }

  NSArray *unfavorableDescriptors = [descriptors.rac_sequence
      filter:^BOOL(id<PTNDescriptor> descriptor) {
        return ![descriptor conformsToProtocol:@protocol(PTNAssetDescriptor)] ||
            !(((id<PTNAssetDescriptor>)descriptor).assetDescriptorCapabilities &
            PTNAssetDescriptorCapabilityFavorite);
      }].array;
  if (unfavorableDescriptors.count) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeInvalidDescriptor
                                 associatedDescriptors:unfavorableDescriptors]];
  }

  NSDictionary<NSString *, NSArray *> *schemeToDescriptors = [self schemeToDescriptors:descriptors];
  NSArray<RACSignal *> *favoriteSignals = [schemeToDescriptors.allKeys.rac_sequence
      map:^RACSignal *(NSString *scheme) {
        return [self favoriteDescriptors:schemeToDescriptors[scheme] favorite:favorite
                             fromManager:self.mapping[scheme]];
      }].array;

  return [RACSignal merge:favoriteSignals];
}

- (RACSignal *)favoriteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors favorite:(BOOL)favorite
                       fromManager:(id<PTNAssetManager>)manager {
  if (![manager respondsToSelector:@selector(favoriteDescriptors:favorite:)]) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnsupportedOperation
                                 associatedDescriptors:descriptors]];
  }

  return [manager favoriteDescriptors:descriptors favorite:favorite];
}

#pragma mark -
#pragma mark Descriptor array multiplexing
#pragma mark -

- (NSDictionary<NSString *, NSArray *> *)schemeToDescriptors:
    (NSArray<id<PTNDescriptor>> *)descriptors {
  NSMutableDictionary<NSString *, NSMutableArray *> *schemeToDescriptors =
      [NSMutableDictionary dictionary];

  for (id<PTNDescriptor> descriptor in descriptors) {
    NSString *scheme = descriptor.ptn_identifier.scheme;
    NSMutableArray *sourceDescriptors = schemeToDescriptors[scheme] ?: [NSMutableArray array];
    [sourceDescriptors addObject:descriptor];
    schemeToDescriptors[scheme] = sourceDescriptors;
  }

  return [schemeToDescriptors copy];
}

- (NSArray<id<PTNDescriptor>> *)unsupportedDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors {
  return [descriptors.rac_sequence filter:^BOOL(id<PTNDescriptor> descriptor) {
    return ![self.mapping.allKeys containsObject:descriptor.ptn_identifier.scheme];
  }].array;
}

- (NSArray<NSString *> *)unsupportedSchemesWithSchemes:(NSArray<NSString *> *)schemes {
  NSMutableSet *schemeSet = [NSMutableSet setWithArray:schemes];
  NSSet *supportedSchemeSet = [NSSet setWithArray:self.mapping.allKeys];
  [schemeSet minusSet:supportedSchemeSet];

  return schemeSet.allObjects;
}

@end

NS_ASSUME_NONNULL_END
