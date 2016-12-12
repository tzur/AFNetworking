// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUFileListProvider.h"

#import <LTKit/NSFileManager+LTKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BLUFileListProvider ()

/// File manager to use for fetching file list.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Holds block that maps file paths to nodes.
@property (readonly, copy, nonatomic) BLUFileListProviderMappingBlock mappingBlock;

@end

@implementation BLUFileListProvider

- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                       mappingBlock:(BLUFileListProviderMappingBlock)mappingBlock {
  if (self = [super init]) {
    _fileManager = fileManager;
    _mappingBlock = [mappingBlock copy];
  }
  return self;
}

- (RACSignal *)nodesForFilesInBaseDirectory:(NSString *)baseDirectory
                                recursively:(BOOL)recursively
                                  predicate:(NSPredicate *)predicate {
  @weakify(self);
  return [[self fetchFilesWithBaseDirectory:baseDirectory recursively:recursively
                                 predicate:predicate]
      map:^NSArray<BLUNode *> *(NSArray<NSString *> *files) {
        @strongify(self);
        return [files.rac_sequence map:self.mappingBlock].array;
      }];
}

- (RACSignal *)fetchFilesWithBaseDirectory:(NSString *)baseDirectory
                               recursively:(BOOL)recursively
                                 predicate:(NSPredicate *)predicate {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);

    NSError *error;
    NSArray<NSString *> * _Nullable files = [self.fileManager
                                             lt_globPath:baseDirectory recursively:recursively
                                             withPredicate:predicate error:&error];
    NSArray<NSString *> *filesWithAbsolutePath = [files.rac_sequence
        map:^NSString *(NSString *filename) {
          return [baseDirectory stringByAppendingPathComponent:filename];
        }].array;

    if (!files) {
      [subscriber sendError:error];
      return nil;
    }

    [subscriber sendNext:filesWithAbsolutePath];
    [subscriber sendCompleted];

    return nil;
  }];
}

@end

NS_ASSUME_NONNULL_END
