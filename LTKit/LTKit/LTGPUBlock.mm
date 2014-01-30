// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUBlock.h"

#import "LTForegroundOperation.h"
#import "LTOperationsExecutor.h"

void LTGPUBlock(LTVoidBlock block) {
  LTParameterAssert(block);

  if ([LTForegroundOperation executor].executionAllowed) {
    block();
  } else {
    [LTForegroundOperation blockOperationWithBlock:block];
  }
}

LTCompletionBlock LTGPUCompletion(LTCompletionBlock block) {
  LTParameterAssert(block);

  LTForegroundOperation *operation = [LTForegroundOperation blockOperationWithBlock:block];
  return operation.foregroundBlock;
}
