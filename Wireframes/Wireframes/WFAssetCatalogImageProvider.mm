// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFAssetCatalogImageProvider.h"

#import "NSErrorCodes+Wireframes.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WFAssetCatalogImageProvider

- (RACSignal *)imageWithURL:(NSURL *)url {
  return [[[RACSignal
      return:url]
      map:^RACTuple *(NSURL *url) {
        return [self assetNameAndBundleTupleForURL:url];
      }]
      tryMap:^UIImage *(RACTuple *assetNameAndBundle, NSError *__autoreleasing *errorPtr) {
        RACTupleUnpack(NSString *assetName, NSURL *bundleURL, NSURL *originalURL) =
            assetNameAndBundle;
        return [self imageForName:assetName bundleURL:bundleURL originalURL:originalURL
                            error:errorPtr];
      }];
}

- (RACTuple *)assetNameAndBundleTupleForURL:(NSURL *)url {
  NSString *imageName;
  NSURL * _Nullable bundleURL;

  if (url.fragment) {
    imageName = url.fragment;
    NSURLComponents *bundleComponents = [NSURLComponents componentsWithURL:url
                                                   resolvingAgainstBaseURL:YES];
    bundleComponents.fragment = nil;
    bundleURL = bundleComponents.URL;
  } else {
    imageName = url.path;
    bundleURL = nil;
  }

  return RACTuplePack(imageName, bundleURL, url);
}

- (nullable UIImage *)imageForName:(NSString *)name bundleURL:(nullable NSURL *)bundleURL
                       originalURL:(NSURL *)originalURL error:(NSError *__autoreleasing *)error {
  NSBundle *bundle = nil;
  if (bundleURL) {
    @try {
      bundle = [NSBundle bundleWithURL:bundleURL];
    }
    @catch (NSException *exception) {
      if (error) {
        *error = [NSError lt_errorWithCode:WFErrorCodeAssetNotFound url:originalURL
                               description:exception.debugDescription];
      }
      return nil;
    }

    if (!bundle) {
      if (error) {
        *error = [NSError lt_errorWithCode:WFErrorCodeAssetNotFound url:originalURL
                               description:[NSString stringWithFormat:
                                            @"No bundle could be loaded at %@", bundleURL]];
      }
      return nil;
    }
  }

  UIImage * _Nullable image = [UIImage imageNamed:name inBundle:bundle
                    compatibleWithTraitCollection:nil];
  if (!image && error) {
    *error = [NSError lt_errorWithCode:WFErrorCodeAssetNotFound url:originalURL
                           description:[NSString stringWithFormat:@"Asset named %@ was not found "
                                        "in %@", name, (bundleURL ?: @"(main bundle)")]];
  }

  return image;
}

@end

NS_ASSUME_NONNULL_END
