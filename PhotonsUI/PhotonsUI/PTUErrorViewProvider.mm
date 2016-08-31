// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUErrorViewProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUErrorViewProvider ()

/// Block used to transform \c NSError and \c NSURL pairs to \c UIView instances.
@property (readonly, nonatomic, copy) PTUErrorViewBlock block;

@end

@implementation PTUErrorViewProvider

- (instancetype)initWithBlock:(PTUErrorViewBlock)block {
  LTParameterAssert(block, @"Given block cannot be nil");
  if (self = [super init]) {
    _block = [block copy];
  }
  return self;
}

- (instancetype)initWithView:(UIView *)view {
  return [self initWithBlock:^UIView *(NSError *, NSURL *) {
    return view;
  }];
}

#pragma mark -
#pragma mark PTUErrorViewProvider
#pragma mark -

- (UIView *)errorViewForError:(NSError *)error associatedURL:(nullable NSURL *)url {
  return self.block(error, url);
}

@end

NS_ASSUME_NONNULL_END
