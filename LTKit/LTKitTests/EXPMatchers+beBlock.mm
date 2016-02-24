// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "EXPMatchers+beBlock.h"

EXPMatcherImplementationBegin(beBlock, (void)) {
  match(^BOOL{
    return [actual isKindOfClass:NSClassFromString(@"NSBlock")];
  });

  failureMessageForTo(^NSString *{
    return [NSString stringWithFormat:@"expected: a block, got: %@", EXPDescribeObject(actual)];
  });

  failureMessageForNotTo(^NSString *{
    return [NSString stringWithFormat:@"expected: not a block, got: %@", EXPDescribeObject(actual)];
  });
}
EXPMatcherImplementationEnd
