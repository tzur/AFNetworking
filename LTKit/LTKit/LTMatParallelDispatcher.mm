// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMatParallelDispatcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMatParallelDispatcher ()

/// Queue that the work is dispatched to.
@property (readonly, nonatomic) dispatch_queue_t queue;

@end

@implementation LTMatParallelDispatcher

- (instancetype)init {
  NSUInteger processorCount = [NSProcessInfo processInfo].processorCount;
  return [self initWithMaxShardCount:processorCount];
}

- (instancetype)initWithMaxShardCount:(NSUInteger)maxShardCount {
  LTParameterAssert(maxShardCount > 0, @"Number of shards must be positive");
  if (self = [super init]) {
    _maxShardCount = maxShardCount;
    _queue = dispatch_queue_create("com.lightricks.LTKit.mat-processing",
                                   DISPATCH_QUEUE_CONCURRENT);
  }
  return self;
}

- (void)processMat:(cv::Mat *)mat processingBlock:(LTMatDispatcherProcessingBlock)processingBlock
        completion:(nullable LTCompletionBlock)completion {
  dispatch_group_t group = dispatch_group_create();

  [self processMat:mat onDispatchGroup:group processingBlock:processingBlock];

  if (completion) {
    dispatch_group_notify(group, dispatch_get_main_queue(), completion);
  }
}

- (void)processMatAndWait:(cv::Mat *)mat
          processingBlock:(LTMatDispatcherProcessingBlock)processingBlock {
  dispatch_group_t group = dispatch_group_create();

  [self processMat:mat onDispatchGroup:group processingBlock:processingBlock];

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)processMat:(cv::Mat *)mat
   onDispatchGroup:(dispatch_group_t)group
   processingBlock:(LTMatDispatcherProcessingBlock)processingBlock {
  LTMatDispatcherShardingBlock shardingBlock = ^cv::Rect(NSUInteger shardIndex,
                                                         NSUInteger shardCount) {
    int rowsPerShard = mat->rows / shardCount;
    int startRow = (int)(shardIndex * rowsPerShard);
    int endRow = (shardIndex == shardCount - 1) ? mat->rows : (int)(shardIndex + 1) * rowsPerShard;

    return cv::Rect(0, startRow, mat->cols, endRow - startRow);
  };

  [self processMat:mat onDispatchGroup:group
     shardingBlock:shardingBlock processingBlock:processingBlock];
}

- (void)processMat:(cv::Mat *)mat
     shardingBlock:(LTMatDispatcherShardingBlock)shardingBlock
   processingBlock:(LTMatDispatcherProcessingBlock)processingBlock
        completion:(nullable LTCompletionBlock)completion {
  dispatch_group_t group = dispatch_group_create();

  [self processMat:mat onDispatchGroup:group
     shardingBlock:shardingBlock processingBlock:processingBlock];

  if (completion) {
    dispatch_group_notify(group, dispatch_get_main_queue(), completion);
  }
}

- (void)processMatAndWait:(cv::Mat *)mat
            shardingBlock:(LTMatDispatcherShardingBlock)shardingBlock
          processingBlock:(LTMatDispatcherProcessingBlock)processingBlock {
  dispatch_group_t group = dispatch_group_create();

  [self processMat:mat onDispatchGroup:group
     shardingBlock:shardingBlock processingBlock:processingBlock];

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)processMat:(cv::Mat *)mat
   onDispatchGroup:(dispatch_group_t)group
     shardingBlock:(LTMatDispatcherShardingBlock)shardingBlock
   processingBlock:(LTMatDispatcherProcessingBlock)processingBlock {
  cv::Rect matRect(cv::Rect(cv::Point(0, 0), mat->size()));
  NSUInteger shardCount = std::max(std::min((int)self.maxShardCount, mat->rows), 1);

  for (NSUInteger shardIndex = 0; shardIndex < shardCount; ++shardIndex) {
    dispatch_group_async(group, self.queue, ^{
      cv::Rect roi(shardingBlock(shardIndex, shardCount));
      LTParameterAssert((roi & matRect) == roi, @"Given shard ROI must be a sub rect of the input "
                        "mat. Given ROI (%d, %d, %d, %d), given mat size: (%d, %d)", roi.x, roi.y,
                        roi.width, roi.height, mat->cols, mat->rows);
      processingBlock(shardIndex, shardCount, (*mat)(roi));
    });
  }
}

@end

NS_ASSUME_NONNULL_END
