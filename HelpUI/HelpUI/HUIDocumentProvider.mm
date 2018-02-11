// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "HUIDocumentProvider.h"

#import "HUIDocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUIDocumentProvider()

/// URL of the location where help documents are stored.
@property (readonly, nonatomic) NSURL *baseURL;

@end

@implementation HUIDocumentProvider

- (instancetype)init {
  return [self initWithBaseURL:[NSBundle mainBundle].bundleURL];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
  if (self = [super init]) {
    _baseURL = baseURL;
  }
  return self;
}

- (RACSignal *)helpDocumentFromPath:(NSString *)featureHierarchyPath {
  return [[[RACSignal return:[self bottommostDocumentURLInPath:featureHierarchyPath]]
      tryMap:^HUIDocument * _Nullable(NSURL *documentURL, NSError *__autoreleasing *errorPtr) {
        return [HUIDocument helpDocumentForJsonAtPath:documentURL.absoluteURL.path error:errorPtr];
      }]
      subscribeOn:RACScheduler.scheduler];
}

- (nullable NSURL *)bottommostDocumentURLInPath:(NSString *)featureHierarchyPath {
  NSFileManager *fileManager = [NSFileManager defaultManager];

  for (NSString *component in featureHierarchyPath.pathComponents) {
    NSString *fileName = [NSString stringWithFormat:@"Help%@.json", component];
    NSURL *documentURL = [NSURL URLWithString:fileName relativeToURL:self.baseURL];
    if ([fileManager fileExistsAtPath:documentURL.absoluteURL.path]) {
      return documentURL;
    }
  }
  return nil;
}

@end

NS_ASSUME_NONNULL_END
