// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMatParallelDispatcher.h"

SpecBegin(LTMatParallelDispatcher)

context(@"initialization", ^{
  it(@"should initialize with given max number of shards", ^{
    static const NSUInteger kMaxShardCount = 5;
    LTMatParallelDispatcher *dispatcher = [[LTMatParallelDispatcher alloc]
                                           initWithMaxShardCount:kMaxShardCount];

    expect(dispatcher.maxShardCount).to.equal(kMaxShardCount);
  });

  it(@"should initialize with default number of shards", ^{
    LTMatParallelDispatcher *sharder = [[LTMatParallelDispatcher alloc] init];
    NSUInteger processorCount = [NSProcessInfo processInfo].processorCount;

    expect(sharder.maxShardCount).to.equal(processorCount);
  });
});

context(@"default sharding", ^{
  __block LTMatParallelDispatcher *dispatcher;
  __block BOOL finished;

  beforeEach(^{
    dispatcher = [[LTMatParallelDispatcher alloc] initWithMaxShardCount:2];
    finished = NO;
  });

  context(@"async processing", ^{
    it(@"should split even mat to two even parts", ^{
      cv::Mat4b image(4, 4);
      image(cv::Rect(0, 0, 4, 2)) = cv::Vec4b(255, 255, 255, 255);
      image(cv::Rect(0, 2, 4, 2)) = cv::Vec4b(255, 0, 0, 255);

      [dispatcher processMat:&image processingBlock:^(NSUInteger shardIndex,
                                                      NSUInteger shardCount,
                                                      cv::Mat shard) {
        dispatch_async(dispatch_get_main_queue(), ^{
          expect(shard.size() == cv::Size(4, 2)).to.beTruthy();

          switch (shardIndex) {
            case 0: {
              expect($(shard)).to.equalScalar($(cv::Scalar(255, 255, 255, 255)));
            } break;
            case 1: {
              expect($(shard)).to.equalScalar($(cv::Scalar(255, 0, 0, 255)));
            } break;
            default:
              expect(NO).to.beTruthy();
          }

          if (shardIndex == shardCount - 1) {
            finished = YES;
          }
        });
      } completion:nil];

      expect(finished).will.beTruthy();
    });

    it(@"should split odd mat to two uneven parts", ^{
      cv::Mat4b image(5, 4);
      image(cv::Rect(0, 0, 4, 2)) = cv::Vec4b(255, 255, 255, 255);
      image(cv::Rect(0, 2, 4, 3)) = cv::Vec4b(255, 0, 0, 255);

      [dispatcher processMat:&image processingBlock:^(NSUInteger shardIndex,
                                                      NSUInteger shardCount,
                                                      cv::Mat shard) {
        dispatch_async(dispatch_get_main_queue(), ^{
          switch (shardIndex) {
            case 0: {
              expect(shard.size() == cv::Size(4, 2)).to.beTruthy();
              expect($(shard)).to.equalScalar($(cv::Scalar(255, 255, 255, 255)));
            } break;
            case 1: {
              expect(shard.size() == cv::Size(4, 3)).to.beTruthy();
              expect($(shard)).to.equalScalar($(cv::Scalar(255, 0, 0, 255)));
            } break;
            default:
              expect(NO).to.beTruthy();
          }

          if (shardIndex == shardCount - 1) {
            finished = YES;
          }
        });
      } completion:nil];

      expect(finished).will.beTruthy();
    });

    it(@"should call completion block", ^{
      cv::Mat4b image(4, 4);

      __block BOOL processingDone;
      __block BOOL completed;

      [dispatcher processMat:&image processingBlock:^(NSUInteger shardIndex, NSUInteger shardCount,
                                                      cv::Mat __unused shard) {
        if (shardIndex == shardCount - 1) {
          processingDone = YES;
        }
      } completion:^{
        expect(processingDone).to.beTruthy();
        completed = YES;
      }];
      
      expect(completed).will.beTruthy();
    });
  });

  context(@"sync processing", ^{
    it(@"should split even mat to two even parts", ^{
      cv::Mat4b image(4, 4);

      [dispatcher processMatAndWait:&image processingBlock:^(NSUInteger shardIndex,
                                                             NSUInteger shardCount,
                                                             cv::Mat shard) {
        shard.setTo(cv::Vec4b(shardIndex, shardCount, shardCount, shardCount));
        if (shardIndex == shardCount - 1) {
          finished = YES;
        }
      }];

      expect(finished).to.beTruthy();
      expect($(image(cv::Rect(0, 0, 4, 2)))).to.equalScalar($(cv::Scalar(0, 2, 2, 2)));
      expect($(image(cv::Rect(0, 2, 4, 2)))).to.equalScalar($(cv::Scalar(1, 2, 2, 2)));
    });

    it(@"should split odd mat to two uneven parts", ^{
      cv::Mat4b image(5, 4);
      image(cv::Rect(0, 0, 4, 2)) = cv::Vec4b(255, 255, 255, 255);
      image(cv::Rect(0, 2, 4, 3)) = cv::Vec4b(255, 0, 0, 255);

      [dispatcher processMatAndWait:&image processingBlock:^(NSUInteger shardIndex,
                                                             NSUInteger shardCount,
                                                             cv::Mat shard) {
        shard.setTo(cv::Vec4b(shardIndex, shardCount, shardCount, shardCount));
        if (shardIndex == shardCount - 1) {
          finished = YES;
        }
      }];

      expect(finished).to.beTruthy();
      expect($(image(cv::Rect(0, 0, 4, 2)))).to.equalScalar($(cv::Scalar(0, 2, 2, 2)));
      expect($(image(cv::Rect(0, 2, 4, 3)))).to.equalScalar($(cv::Scalar(1, 2, 2, 2)));
    });
  });
});

context(@"custom sharding", ^{
  __block LTMatParallelDispatcher *dispatcher;

  __block LTMatDispatcherShardingBlock shardingBlock = ^cv::Rect(NSUInteger shardIndex,
                                                                 NSUInteger) {
    return cv::Rect((int)shardIndex, (int)shardIndex, 1, 1);
  };

  beforeEach(^{
    dispatcher = [[LTMatParallelDispatcher alloc] initWithMaxShardCount:2];
  });

  context(@"async processing", ^{
    it(@"should send shards as defined by the sharding block", ^{
      cv::Mat4b image(2, 2, cv::Vec4b(0, 0, 0, 255));
      __block BOOL completed = NO;

      [dispatcher processMat:&image shardingBlock:shardingBlock
             processingBlock:^(NSUInteger shardIndex,
                               NSUInteger,
                               cv::Mat shard) {
               shard.setTo(cv::Vec4b(shardIndex, 0, 0, 128));
             } completion:^{
               completed = YES;
             }];

      cv::Mat4b expectedImage(image.clone());
      expectedImage(0, 0) = cv::Vec4b(0, 0, 0, 128);
      expectedImage(1, 1) = cv::Vec4b(1, 0, 0, 128);

      expect(completed).will.beTruthy();
      expect($(image)).to.equalMat($(expectedImage));
    });
  });

  context(@"sync processing", ^{
    it(@"should send shards as defined by the sharding block", ^{
      cv::Mat4b image(2, 2, cv::Vec4b(0, 0, 0, 255));

      [dispatcher processMatAndWait:&image shardingBlock:shardingBlock
                    processingBlock:^(NSUInteger shardIndex,
                                      NSUInteger,
                                      cv::Mat shard) {
                      shard.setTo(cv::Vec4b(shardIndex, 0, 0, 128));
                    }];

      cv::Mat4b expectedImage(image.clone());
      expectedImage(0, 0) = cv::Vec4b(0, 0, 0, 128);
      expectedImage(1, 1) = cv::Vec4b(1, 0, 0, 128);

      expect($(image)).to.equalMat($(expectedImage));
    });
  });
});

context(@"small input", ^{
  __block LTMatParallelDispatcher *dispatcher;

  beforeEach(^{
    dispatcher = [[LTMatParallelDispatcher alloc] initWithMaxShardCount:4];
  });

  it(@"should executing less shards than the maximal number for small inputs", ^{
    cv::Mat4b image(2, 2, cv::Vec4b(0, 0, 0, 255));

    [dispatcher processMatAndWait:&image
                  processingBlock:^(NSUInteger shardIndex,
                                    NSUInteger shardCount,
                                    cv::Mat shard) {
                    shard.setTo(cv::Vec4b(shardIndex, shardCount, 0, 128));
                  }];

    cv::Mat4b expectedImage(image.clone());
    expectedImage(0, 0) = cv::Vec4b(0, 2, 0, 128);
    expectedImage(1, 1) = cv::Vec4b(1, 2, 0, 128);
    
    expect($(image)).to.equalMat($(expectedImage));
  });

  it(@"should execute a single shard for an empty input", ^{
    cv::Mat4b image;

    __block cv::Size size;
    [dispatcher processMatAndWait:&image
                  processingBlock:^(NSUInteger, NSUInteger, cv::Mat shard) {
                    size = shard.size();
                  }];

    expect(size == cv::Size(0, 0)).to.beTruthy();
  });
});

SpecEnd
