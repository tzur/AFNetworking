// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "EXPMatchers+beBlock.h"

EXPMatcherImplementationBegin(beBlock, (void)) {
  match(^BOOL(id actual) {
    return [actual isKindOfClass:NSClassFromString(@"NSBlock")];
  });

  failureMessageForTo(^NSString *(id actual) {
    return [NSString stringWithFormat:@"expected: a block, got: %@", EXPDescribeObject(actual)];
  });

  failureMessageForNotTo(^NSString *(id actual) {
    return [NSString stringWithFormat:@"expected: not a block, got: %@", EXPDescribeObject(actual)];
  });
}
EXPMatcherImplementationEnd
