// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageLoader.h"

#import <LTKit/NSError+LTKit.h>

#import "NSErrorCodes+Wireframes.h"
#import "WFAssetCatalogImageProvider.h"
#import "WFPaintCodeImageProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFImageLoader ()

/// Providers mapped by URL schemes.
@property (readonly, nonatomic) NSDictionary<NSString *, id<WFImageProvider>> *providers;

@end

@implementation WFImageLoader

- (instancetype)initWithProviders:(NSDictionary<NSString *, id<WFImageProvider>> *)providers {
  if (self = [super init]) {
    _providers = [providers copy];
  }
  return self;
}

- (instancetype)init {
  WFAssetCatalogImageProvider *assetCatalogImageProvider =
      [[WFAssetCatalogImageProvider alloc] init];
  WFPaintCodeImageProvider *paintCodeImageProvider = [[WFPaintCodeImageProvider alloc] init];
  return [self initWithProviders:@{
    @"paintcode": paintCodeImageProvider,
    @"file": assetCatalogImageProvider,
    @"": assetCatalogImageProvider
  }];
}

- (RACSignal *)imageWithURL:(NSURL *)url {
  // -[NSURL scheme] is nonnull, but it can have nil values.
  NSString *scheme = [url.scheme lowercaseString] ?: @"";

  id<WFImageProvider> _Nullable provider = self.providers[scheme];
  if (!provider) {
    NSError *error = [NSError lt_errorWithCode:WFErrorCodeUnrecognizedURLScheme url:url
                                   description:[NSString stringWithFormat:@"No image provider "
                                                "could be found for scheme \'%@\'", scheme]];
    return [RACSignal error:error];
  }

  return [provider imageWithURL:url];
}

@end

NS_ASSUME_NONNULL_END
