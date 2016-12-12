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
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:BLUErrorCodePathNotFound path:path];
          }
          return nil;
        }

        return subtree;
      }]
      distinctUntilChanged];
}

- (RACSignal *)blu_addChildNodes:(RACSignal *)signal toPath:(NSString *)path {
  return [[self
      combineLatestWith:[signal startWith:@[]]]
      tryMap:^BLUNode * _Nullable(RACTuple *values, NSError *__autoreleasing *errorPtr) {
        RACTupleUnpack(BLUNode *node, NSArray<BLUNode *> *childNodes) = values;

        LTParameterAssert([node isKindOfClass:[BLUNode class]], @"Signal must carry only BLUNode "
                          "instances, got %@ instead", [node class]);
        LTParameterAssert([childNodes isKindOfClass:[NSArray class]], @"Given signal must be an "
                          "NSArray, got %@ instead", [childNodes class]);

        BLUNode * _Nullable subtree = node[path];
        if (!subtree) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:BLUErrorCodePathNotFound path:path];
          }
          return nil;
        }

        if (!childNodes.count) {
          return node;
        } else {
          NSIndexSet *indexes =
              [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(subtree.childNodes.count,
                                                                 childNodes.count)];
          return [node nodeByInsertingChildNodes:childNodes toNodeAtPath:path atIndexes:indexes];
        }
      }];
}

- (RACSignal *)blu_insertChildNodes:(RACSignal *)signal toPath:(NSString *)path {
  RACSignal *signalWithInitial = [signal startWith:RACTuplePack(@[], [NSIndexSet indexSet])];

  return [[self
      combineLatestWith:signalWithInitial]
      tryMap:^BLUNode * _Nullable(RACTuple *values, NSError *__autoreleasing *errorPtr) {
        RACTupleUnpack(BLUNode *node, RACTuple *childNodesAndIndexes) = values;
        RACTupleUnpack(NSArray<BLUNode *> *childNodes, NSIndexSet *indexes) = childNodesAndIndexes;

        LTParameterAssert([node isKindOfClass:[BLUNode class]], @"Signal must carry only BLUNode "
                          "instances, got %@ instead", [node class]);
        LTParameterAssert([childNodes isKindOfClass:[NSArray class]], @"Signal's first tuple item "
                          "must be an NSArray, got %@ instead", [childNodes class]);
        LTParameterAssert([indexes isKindOfClass:[NSIndexSet class]], @"Signal's second tuple item "
                          "must be an NSIndexSet, got %@ instead", [childNodes class]);

        BLUNode * _Nullable subtree = node[path];
        if (!subtree) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:BLUErrorCodePathNotFound path:path];
          }
          return nil;
        }

        if (!childNodes.count) {
          return node;
        } else {
          return [node nodeByInsertingChildNodes:childNodes toNodeAtPath:path atIndexes:indexes];
        }
      }];
}

@end

NS_ASSUME_NONNULL_END
