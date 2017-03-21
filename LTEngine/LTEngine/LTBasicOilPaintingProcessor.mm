// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBasicOilPaintingProcessor.h"

#import "LTMatParallelDispatcher.h"
#import "LTTexture+Factory.h"

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

/// This algorithm is based on Huang's O(r) median filtering algorithm (Two-Dimensional Signal
/// Processing II: Transforms and Median Filters. Berlin: Springer-Verlag, pp. 209-211) and OpenCV's
/// cv::medianBlur implementation. Since here the purpose is to find the maximal value and not the
/// median, a compelete sweep over the histogram is required, instead of a cumulative sum up to when
/// the window size / 2 is encountered.
///
/// Futher optimization strategies: there are two additional papers that implement an O(log(r)) and
/// O(1) median filtering:
/// - B. Weiss, “Fast Median and Bilateral Filtering,” ACM Transactions on Graphics (TOG), vol. 25,
///   no. 3, pp. 519–526, 2006.
/// - S. Perreault and P. Hebert. Median filtering in constant time. TIP, pages 2389-2394, 2007.
///
/// For small radiuses, it seems that the O(log(r)) will be significantly faster because of the
/// large constant of the O(1) algorithm and relatively bad cache coherency.
///
/// Notice: since the performance of this algorithm is critical and underwent a considerable
/// optimization process, make sure that the performance is not degraded after the code is modified.
static void LTBasicOilProcessInternal(const cv::Mat &srcMat, cv::Mat &dstMat, int radius,
                                      const cv::Mat &alphaMat, int numBins) {
  int histogram[4][256];

  cv::Size size = dstMat.size();
  const uchar *src = srcMat.ptr();
  const uchar *alpha = alphaMat.ptr();
  uchar *dst = dstMat.ptr();

  int srcStep = (int)srcMat.step;
  int alphaStep = (int)alphaMat.step;
  int dstStep = (int)dstMat.step;

  const uchar *srcMax = src + size.height * srcStep;

  // Sweep the image in a snail form: start from top left (0, 0), go down till the bottom, and then
  // move one column to the right. Go up to the top, move one column to the right and continue this
  // process for the entire image.
  for (int x = 0; x < size.width; ++x, src += 4, dst += 4, ++alpha) {
    uchar *currentDst = dst;
    const uchar *srcTop = src;
    const uchar *srcBottom = src;
    const uchar *alphaSrc = alpha;

    int srcStep1 = srcStep;
    int alphaStep1 = alphaStep;
    int dstStep1 = dstStep;

    // Sweep top->bottom for even columns and bottom->top for odd columns.
    if (x % 2 != 0) {
      srcBottom = srcTop += srcStep * (size.height - 1);
      alphaSrc += alphaStep * (size.height - 1);
      currentDst += dstStep * (size.height - 1);
      srcStep1 = -srcStep1;
      alphaStep1 = -alphaStep1;
      dstStep1 = -dstStep1;
    }

    // Zero histogram.
    memset(histogram, 0, sizeof(histogram[0]) * 4);

    for (int y = 0; y <= radius / 2; ++y) {
      int factor = y > 0 ? 1 : radius / 2 + 1;
      for (int i = 0; i < radius * 4; i += 4) {
        int value = srcBottom[i + 3];
        // Boundary - add values of bottom or top row replicated as half the window size.
        histogram[0][value] += factor * srcBottom[i + 0];
        histogram[1][value] += factor * srcBottom[i + 1];
        histogram[2][value] += factor * srcBottom[i + 2];
        histogram[3][value] += factor;
      }

      if ((srcStep1 > 0 && y < size.height - 1) || (srcStep1 < 0 && size.height - y - 1 > 0)) {
        srcBottom += srcStep1;
      }
    }

    for (int y = 0; y < size.height; y++, currentDst += dstStep1, alphaSrc += alphaStep1) {
      // Find maximal bin.
      int maxValue = 0;
      int maxBin = 0;

      for (int i = 0; i < numBins; ++i) {
        if (histogram[3][i] > maxValue) {
          maxValue = histogram[3][i];
          maxBin = i;
        }
      }

      // Write values to destination.
      currentDst[0] = histogram[0][maxBin] / histogram[3][maxBin];
      currentDst[1] = histogram[1][maxBin] / histogram[3][maxBin];
      currentDst[2] = histogram[2][maxBin] / histogram[3][maxBin];
      currentDst[3] = alphaSrc[0];

      if (y + 1 == size.height) {
        break;
      }

      for (int i = 0; i < radius * 4; i += 4) {
        int valueToRemove = srcTop[i + 3];
        histogram[0][valueToRemove] -= srcTop[i + 0];
        histogram[1][valueToRemove] -= srcTop[i + 1];
        histogram[2][valueToRemove] -= srcTop[i + 2];
        histogram[3][valueToRemove]--;

        int valueToAdd = srcBottom[i + 3];
        histogram[0][valueToAdd] += srcBottom[i + 0];
        histogram[1][valueToAdd] += srcBottom[i + 1];
        histogram[2][valueToAdd] += srcBottom[i + 2];
        histogram[3][valueToAdd]++;
      }

      if ((srcStep1 > 0 && srcBottom + srcStep1 < srcMax) ||
          (srcStep1 < 0 && srcBottom + srcStep1 >= src)) {
        srcBottom += srcStep1;
      }

      if (y >= radius / 2) {
        srcTop += srcStep1;
      }
    }
  }
}

static void LTBasicOilPainting(const cv::Mat &src, cv::Mat *dst, int kernelSize, int numberOfBins) {
  LTParameterAssert(src.channels() == dst->channels(),
                    @"Source and destination channel count must be equal");
  LTParameterAssert(src.type() == CV_8UC4, @"Oil painting works only on byte RGBA images");

  cv::Mat4b srcWithBorder;
  cv::copyMakeBorder(src, srcWithBorder, 0, 0, kernelSize / 2, kernelSize / 2,
                     cv::BORDER_REPLICATE);

  cv::Mat1b alphaValues(src.rows, src.cols);
  int rgbaToAlphaIndexMapping[] = {3, 0};
  cv::mixChannels(&src, 1, &alphaValues, 1, rgbaToAlphaIndexMapping, 1);

  std::transform(srcWithBorder.begin(), srcWithBorder.end(), srcWithBorder.begin(),
                 [numberOfBins](const cv::Vec4b &v) {
    return cv::Vec4b(v[0], v[1], v[2], (v[0] + v[1] + v[2]) / 3.0 * ((numberOfBins - 1) / 255.0));
                 });

  int shards = std::min((int)[NSProcessInfo processInfo].processorCount, dst->cols);
  int colsPerShard = dst->cols / shards;
  int borderSize = srcWithBorder.cols - src.cols;

  LTMatParallelDispatcher *dispatcher =
      [[LTMatParallelDispatcher alloc] initWithMaxShardCount:shards];

  [dispatcher processMatAndWait:&srcWithBorder
                  shardingBlock:^(NSUInteger shardIndex, NSUInteger shardCount) {
                    int startCol = (int)shardIndex * colsPerShard;
                    int endCol = (shardIndex == shardCount - 1) ?
                        dst->cols : (int)(shardIndex + 1) * colsPerShard;
                    return cv::Rect(startCol, 0, endCol - startCol + borderSize, src.rows);
                  }
                processingBlock:^(NSUInteger shardIndex, NSUInteger shardCount, cv::Mat srcShard) {
                  int startCol = (int)shardIndex * colsPerShard;
                  int endCol = (shardIndex == shardCount - 1) ?
                      dst->cols : (int)(shardIndex + 1) * colsPerShard;
                  cv::Mat dstShard = (*dst)(cv::Rect(startCol, 0, endCol - startCol, dst->rows));
                  cv::Mat alphaShard = alphaValues(cv::Rect(startCol, 0, endCol - startCol,
                                                             alphaValues.rows));
                  LTBasicOilProcessInternal(srcShard, dstShard, kernelSize, alphaShard,
                                            numberOfBins);
                }];
}

- (void)process {
  [self.inputTexture mappedImageForReading:^(const cv::Mat &inputImage, BOOL) {
    [self.outputTexture mappedImageForWriting:^(cv::Mat *outputImage, BOOL) {
      LTBasicOilPainting(inputImage, outputImage, (int)self.radius * 2 + 1, (int)self.quantization);
    }];
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(NSUInteger, quantization, Quantization, 2, 255, 20);

LTProperty(NSUInteger, radius, Radius, 1, 10, 3);

@end
