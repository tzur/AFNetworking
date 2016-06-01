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
  id<PTNAssetManager> assetManager = self.mapping[url.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError lt_errorWithCode:PTNErrorCodeUnrecognizedURLScheme url:url]];
  }
  return [assetManager fetchAlbumWithURL:url];
}

#pragma mark -
#pragma mark Asset fetching
#pragma mark -

- (RACSignal *)fetchDescriptorWithURL:(NSURL *)url {
  id<PTNAssetManager> assetManager = self.mapping[url.scheme];
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
  id<PTNAssetManager> assetManager = self.mapping[descriptor.ptn_identifier.scheme];
  if (!assetManager) {
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                  associatedDescriptor:descriptor]];
  }
  return [assetManager fetchImageWithDescriptor:descriptor resizingStrategy:resizingStrategy
                                        options:options];
}

#pragma mark -
#pragma mark Deletion
#pragma mark -

- (RACSignal *)deleteDescriptors:(NSArray<id<PTNDescriptor>> *)descriptors {
  NSDictionary<NSString *, NSArray<id<PTNDescriptor>> *> *schemeToDescriptors =
      [self schemeToDescriptors:descriptors];

  NSArray *unsupportedSchemes = [self unsupportedSchemesWithSchemes:schemeToDescriptors.allKeys];
  if (unsupportedSchemes.count > 0) {
    NSArray<id<PTNDescriptor>> *unsupportedDescriptors = [[unsupportedSchemes.rac_sequence
        map:^RACSequence *(NSString *scheme) {
          return schemeToDescriptors[scheme].rac_sequence;
        }]
        flatten].array;

    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeUnrecognizedURLScheme
                                 associatedDescriptors:unsupportedDescriptors]];
  }

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
    return [RACSignal error:[NSError ptn_errorWithCode:PTNErrorCodeAssetDeletionFailed
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

  return [assetManager removeDescriptors:descriptors fromAlbum:albumDescriptor];
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

- (NSArray<NSString *> *)unsupportedSchemesWithSchemes:(NSArray<NSString *> *)schemes {
  NSMutableSet *schemeSet = [NSMutableSet setWithArray:schemes];
  NSSet *supportedSchemeSet = [NSSet setWithArray:self.mapping.allKeys];
  [schemeSet minusSet:supportedSchemeSet];

  return schemeSet.allObjects;
}

@end

NS_ASSUME_NONNULL_END
