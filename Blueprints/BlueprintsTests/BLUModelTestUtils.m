// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUModelTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUFakeProviderDescriptor

- (instancetype)init {
  if (self = [super init]) {
    _fakeProvider = [[BLUFakeProvider alloc] init];
  }
  return self;
}

- (id<BLUProvider>)provider {
  return _fakeProvider;
}

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

@interface BLUFakeProvider ()

/// Subject for sending the node data manually.
@property (readonly, nonatomic) RACSubject *nodeDataSubject;

@end

@implementation BLUFakeProvider

- (instancetype)init {
  if (self = [super init]) {
    _nodeDataSubject = [RACSubject subject];
  }
  return self;
}

- (void)sendNodeData:(BLUNodeData *)nodeData {
  [self.nodeDataSubject sendNext:nodeData];
}

- (RACSignal *)provideNodeData {
  return self.nodeDataSubject;
}

@end

NS_ASSUME_NONNULL_END
