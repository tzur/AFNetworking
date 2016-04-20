// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACSignal+BLUNode.h"

#import "BLUNode.h"
#import "BLUNode+Operations.h"
#import "BLUNode+Tree.h"
#import "BLUNodeCollection.h"
#import "NSErrorCodes+Blueprints.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (BLUNode)

- (RACSignal *)blu_subtreeAtPath:(NSString *)path {
  return [[self
      tryMap:^BLUNode *(BLUNode *node, NSError *__autoreleasing *errorPtr) {
        LTParameterAssert([node isKindOfClass:[BLUNode class]], @"Signal must carry only BLUNode "
                          "instances, got %@ instead", [node class]);
        BLUNode * _Nullable subtree = node[path];
        if (!subtree) {
          *errorPtr = [NSError lt_errorWithCode:BLUErrorCodePathNotFound path:path];
          return nil;
        }

        return subtree;
      }]
      distinctUntilChanged];
}

@end

NS_ASSUME_NONNULL_END
