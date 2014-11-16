// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBasicOilPaintingProcessor.h"

#import "LTTexture+Factory.h"

typedef struct {
  uchar r;
  uchar g;
  uchar b;
  uchar a;
} LTVector4u;

typedef struct {
  int r;
  int g;
  int b;
  int histogram;
} LTVector4i;

typedef std::vector<LTVector4i> LTHistogram;

@interface LTBasicOilPaintingProcessor ()

/// Input texture of the processor.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Output texture of the processor.
@property (strong, nonatomic) LTTexture *outputTexture;

@end

@implementation LTBasicOilPaintingProcessor

- (instancetype)initWithInputTexture:(LTTexture *)inputTexture
                       outputTexture:(LTTexture *)outputTexture {
  if (self = [super init]) {
    LTParameterAssert(inputTexture.size == outputTexture.size,
                      @"Input and output textures should have the same size.");
    self.inputTexture = inputTexture;
    self.outputTexture = outputTexture;

    [self resetInputModel];
  }
  return self;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTBasicOilPaintingProcessor, quantization),
      @instanceKeypath(LTBasicOilPaintingProcessor, radius)
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

/// In order to improve the runnning time of the algorithm, update the local histogram instead to
/// recompute it for every pixel. Update is done by adding the rightmost column of the sliding
/// window and subtracting the column that comes before the leftmost column of the sliding window.
/// Notice: since the performance of this algorithm is critical and underwent a considerable
/// optimization process, make sure that the performance is not degraded after the code is modified.
inline void LTBasicOilProcess(const cv::Mat &transposedImage, int startRow, int endRow,
                              int halfWindowSize, int numberOfBins, cv::Mat *outputImage) {
  int windowSize = halfWindowSize * 2;

  LTHistogram sums(numberOfBins);

  for (int row = startRow; row < endRow; ++row) {
    LTVector4u *outputRow = outputImage->ptr<LTVector4u>(row);
    std::fill(sums.begin(), sums.end(), LTVector4i({.r = 0, .g = 0, .b = 0, .histogram = 0}));

    int minSlidingRow = std::max(0, row - halfWindowSize);
    int maxSlidingRow = std::min(row + halfWindowSize + 1, transposedImage.cols);

    // To traverse the columns, go over the rows of the transposed image. This moderately improves
    // the memory access pattern.
    for (int column = 0; column < transposedImage.rows; ++column) {
      const LTVector4u *prevCol = nil;
      const LTVector4u *nextCol = nil;

      if (column + halfWindowSize < transposedImage.rows) {
        nextCol = transposedImage.ptr<LTVector4u>(column + halfWindowSize);
      }

      if (column > windowSize) {
        prevCol = transposedImage.ptr<LTVector4u>(column - halfWindowSize - 1);
      }

      // Add column statistics to the histogram.
      if (column + halfWindowSize < transposedImage.rows) {
        for (int slidingRow = minSlidingRow; slidingRow < maxSlidingRow; ++slidingRow) {
          LTVector4u pixel = *(nextCol + slidingRow);
          int intensity = pixel.a;
          LTVector4i sum = sums[intensity];
          sum.histogram++;
          sum.r += pixel.r;
          sum.g += pixel.g;
          sum.b += pixel.b;
          sums[intensity] = sum;
        }
      }

      // Remove column statistics from the histogram.
      if (column > windowSize) {
        for (int slidingRow = minSlidingRow; slidingRow < maxSlidingRow; ++slidingRow) {
          LTVector4u pixel = *(prevCol + slidingRow);
          int intensity = pixel.a;
          LTVector4i sum = sums[intensity];
          sum.histogram--;
          sum.r -= pixel.r;
          sum.g -= pixel.g;
          sum.b -= pixel.b;
          sums[intensity] = sum;
        }
      }

      auto maxValue = std::max_element(sums.begin(), sums.end(), [](const LTVector4i &a,
                                                                    const LTVector4i &b) {
        return a.histogram < b.histogram;
      });
      auto maxIndex = std::distance(sums.begin(), maxValue);
      LTVector4i sum = sums[maxIndex];
      *outputRow = {
        .r = (uchar)(sum.r / maxValue->histogram),
        .g = (uchar)(sum.g / maxValue->histogram),
        .b = (uchar)(sum.b / maxValue->histogram),
        .a = 255
      };
      ++outputRow;
    }
  }
}

- (void)process {
  // TODO:(yaron) Figure out multithreading interface for image processors.
  dispatch_queue_t queue = dispatch_queue_create("com.lightricks.LTKit.oil-painting",
                                                 DISPATCH_QUEUE_CONCURRENT);
  dispatch_group_t group = dispatch_group_create();

  int numberOfBins = (int)self.quantization;
  int halfWindowSize = (int)self.radius;

  [self.inputTexture mappedImageForReading:^(const cv::Mat &inputImage, BOOL) {
    cv::Mat4b transposedImage(inputImage.cols, inputImage.rows);
    cv::transpose(inputImage, transposedImage);
    std::transform(transposedImage.begin(), transposedImage.end(), transposedImage.begin(),
                   [numberOfBins](const cv::Vec4b &v) {
      return cv::Vec4b(v[0], v[1], v[2], (v[0] + v[1] + v[2]) / 3.0 * ((numberOfBins - 1) / 255.0));
    });

    [self.outputTexture mappedImageForWriting:^(cv::Mat *outputImage, BOOL) {
      int shards = (int)[NSProcessInfo processInfo].processorCount;
      int rowsPerShard = outputImage->rows / shards;

      for (int i = 0; i < shards; ++i) {
        int endRow = (i == shards - 1) ? outputImage->rows : (i + 1) * rowsPerShard;

        dispatch_group_async(group, queue, ^{
          LTBasicOilProcess(transposedImage, i * rowsPerShard, endRow, halfWindowSize, numberOfBins,
                            outputImage);
        });
      }

      dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    }];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(NSUInteger, quantization, Quantization, 2, 255, 20);

LTProperty(NSUInteger, radius, Radius, 1, 100, 3);

@end
