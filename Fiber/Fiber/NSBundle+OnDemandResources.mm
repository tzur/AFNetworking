// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSBundle+OnDemandResources.h"

#import <LTKit/LTProgress.h>

#import "FBROnDemandResource.h"
#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark NSBundleResourceRequest+Fiber
#pragma mark -

/// Category wrapping the \c NSBundleResourceRequest functionality, exposing only \c bundle property
/// for accessing the request resources.
@interface NSBundleResourceRequest (Fiber) <FBROnDemandResource>
@end

@implementation NSBundleResourceRequest (Fiber)
@end

#pragma mark -
#pragma mark NSBundle+OnDemandResource
#pragma mark -

@implementation NSBundle (OnDemandResources)

- (RACSignal *)fbr_beginAccessToResourcesWithTags:(NSSet<NSString *> *)tags {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSBundleResourceRequest *request = [self fbr_bundleResourceRequestWithTags:tags];
    RACDisposable *progressDisposable = [RACObserve(request.progress, fractionCompleted)
        subscribeNext:^(NSNumber *fractionCompleted) {
          [subscriber sendNext:[[LTProgress alloc]
                                initWithProgress:[fractionCompleted doubleValue]]];
        }];

    [request beginAccessingResourcesWithCompletionHandler:^(NSError * _Nullable error) {
      if (!error) {
        [subscriber sendNext:[[LTProgress alloc] initWithResult:request]];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:[NSError lt_errorWithCode:FBRErrorCodeOnDemandResourcesRequestFailed
                                        underlyingError:error]];
      }
    }];

    RACDisposable *accessDisposable = [RACDisposable disposableWithBlock:^{
      [request.progress cancel];
    }];

    return [RACCompoundDisposable compoundDisposableWithDisposables:@[
      progressDisposable,
      accessDisposable
    ]];
  }];
}

- (RACSignal *)fbr_conditionallyBeginAccessToResourcesWithTags:(NSSet<NSString *> *)tags {
  return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    NSBundleResourceRequest *request = [self fbr_bundleResourceRequestWithTags:tags];
    [request conditionallyBeginAccessingResourcesWithCompletionHandler:^(BOOL resourcesAvailable) {
      [subscriber sendNext:resourcesAvailable ? request : nil];
      [subscriber sendCompleted];
    }];

    return nil;
  }];
}

- (NSBundleResourceRequest *)fbr_bundleResourceRequestWithTags:(NSSet<NSString *> *)tags {
  return [[NSBundleResourceRequest alloc] initWithTags:tags bundle:self];
}

@end

NS_ASSUME_NONNULL_END
