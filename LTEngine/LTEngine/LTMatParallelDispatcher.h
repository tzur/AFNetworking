// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Manages the workload of processing a \c cv::Mat by sharding the work across multiple workers.
/// The client of this class can let the manager use a default number of shards (which will map each
/// shard to a CPU core), or define a custom number of shards.
///
/// By default, the input \c cv::Mat will be sharded by rows, but the client can customize this by
/// supplying a sharding function.
@interface LTMatParallelDispatcher : NSObject

/// Initializes with default max number of shards to split the inputs to, which will be equal to the
/// number of cores in the system.
- (instancetype)init;

/// Initializes with the given max number of shards to split the inputs to, which must be a positive
/// value.
- (instancetype)initWithMaxShardCount:(NSUInteger)maxShardCount NS_DESIGNATED_INITIALIZER;

/// Block which is called for each worker that is used to process each shard.
typedef void (^LTMatDispatcherProcessingBlock)(NSUInteger shardIndex, NSUInteger shardCount,
                                               cv::Mat shard);

/// Processes the given \c mat by splitting it by rows to shards and calling a processing block on
/// each of them. Once all the shards had been processed, the \c completion block will be called on
/// the main queue.
///
/// For each shard, the \c shardProcessingBlock will be called on a non-main queue with the shard
/// it should process as a separate \c cv::Mat.
///
/// @important the actual shard count given in the processing block is defined by
/// MAX(MIN(maxShardCount, mat->rows), 1) to minimalize the number of workers that have no work to
/// do.
- (void)processMat:(cv::Mat *)mat processingBlock:(LTMatDispatcherProcessingBlock)processingBlock
        completion:(nullable LTCompletionBlock)completion;

/// Processes the given \c mat by splitting it by rows to shards and calling a processing block on
/// each of them. This method blocks until the processing has been completed.
///
/// For each shard, the \c shardProcessingBlock will be called on a non-main queue with the shard
/// it should process as a separate \c cv::Mat.
///
/// @important the actual shard count given in the processing block is defined by
/// MAX(MIN(maxShardCount, mat->rows), 1) to minimalize the number of workers that have no work to
/// do.
- (void)processMatAndWait:(cv::Mat *)mat
          processingBlock:(LTMatDispatcherProcessingBlock)processingBlock;

/// Block that returns an ROI for a shard for the input \c mat, given the current \c shardIndex and
/// \c shardCount. The returned cv::Rect must be contained inside the rect defined by
/// (0, 0, mat->cols, mat->rows).
typedef cv::Rect (^LTMatDispatcherShardingBlock)(NSUInteger shardIndex, NSUInteger shardCount);

/// Processes the given \c mat by splitting it to shards and calling a processing block on each of
/// them. Once all the shards had been processed, the \c completion block will be called on the main
/// queue.
///
/// Use \c shardingBlock to explicitly define each shard. Returning invalid shards that are out of
/// the input \c mat bounds will raise an exception. For each shard, the \c shardProcessingBlock
/// will be called on a non-main queue with the shard it should process as a separate \c cv::Mat.
///
/// @important the actual shard count given in the processing block is defined by
/// MAX(MIN(maxShardCount, mat->rows), 1) to minimalize the number of workers that have no work to
/// do.
- (void)processMat:(cv::Mat *)mat
     shardingBlock:(LTMatDispatcherShardingBlock)shardingBlock
   processingBlock:(LTMatDispatcherProcessingBlock)processingBlock
        completion:(nullable LTCompletionBlock)completion;

/// Processes the given \c mat by splitting it to shards and calling a processing block on each of
/// them. This method blocks until the processing has been completed.
///
/// Use \c shardingBlock to explicitly define each shard. Returning invalid shards that are out of
/// the input \c mat bounds will raise an exception. For each shard, the \c shardProcessingBlock
/// will be called on a non-main queue with the shard it should process as a separate \c cv::Mat.
///
/// @important the actual shard count given in the processing block is defined by
/// MAX(MIN(maxShardCount, mat->rows), 1) to minimalize the number of workers that have no work to
/// do.
- (void)processMatAndWait:(cv::Mat *)mat
            shardingBlock:(LTMatDispatcherShardingBlock)shardingBlock
          processingBlock:(LTMatDispatcherProcessingBlock)processingBlock;

/// Maximal number of shards to split the workload to.
@property (readonly, nonatomic) NSUInteger maxShardCount;

@end

NS_ASSUME_NONNULL_END
