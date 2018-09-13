// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingSuperPixel.h"

SpecBegin(PNKInpaintingSuperPixel)

context(@"initialization", ^{
  it(@"should create superpixel with correct center, bounding box and offsets", ^{
    std::vector<cv::Point> coordinates = {{2, 2}, {2, 6}, {6, 2}, {6, 6}};

    cv::Point expectedCenter(4, 4);
    cv::Rect expectedBoundingBox(2, 2, 5, 5);
    auto expectedOffsets = cv::Mat(coordinates) - cv::Scalar(expectedCenter.x, expectedCenter.y);

    auto superpixel = [[PNKInpaintingSuperPixel alloc] initWithCoordinates:coordinates];

    expect($(superpixel.center == expectedCenter)).to.beTruthy();
    expect($(superpixel.boundingBox == expectedBoundingBox)).to.beTruthy();
    expect($(superpixel.offsets)).to.equalMat($(expectedOffsets));
  });

  it(@"should create superpixel with correct center, bounding box and offsets when center is not "
     "a pair of integers", ^{
    std::vector<cv::Point> coordinates = {{0, 2}, {2, 0}, {2, 2}};

    cv::Point expectedCenter(1, 1);
    cv::Rect expectedBoundingBox(0, 0, 3, 3);
    auto expectedOffsets = cv::Mat(coordinates) - cv::Scalar(expectedCenter.x, expectedCenter.y);

    auto superpixel = [[PNKInpaintingSuperPixel alloc] initWithCoordinates:coordinates];

    expect($(superpixel.center == expectedCenter)).to.beTruthy();
    expect($(superpixel.boundingBox == expectedBoundingBox)).to.beTruthy();
    expect($(superpixel.offsets)).to.equalMat($(expectedOffsets));
  });
});

context(@"create other superpixel", ^{
  it(@"should create correct superpixel given new center", ^{
    std::vector<cv::Point> coordinates = {{2, 2}, {2, 6}, {6, 2}, {6, 6}};

    auto superpixel = [[PNKInpaintingSuperPixel alloc] initWithCoordinates:coordinates];

    cv::Point otherCenter(10, 15);
    auto otherSuperPixel = [superpixel superPixelCenteredAt:otherCenter];

    cv::Rect expectedBoundingBox(superpixel.boundingBox.tl() - superpixel.center + otherCenter,
                                 superpixel.boundingBox.size());

    expect($(otherSuperPixel.center == otherCenter)).to.beTruthy();
    expect($(otherSuperPixel.boundingBox == expectedBoundingBox)).to.beTruthy();
    expect($(otherSuperPixel.offsets)).to.equalMat($(superpixel.offsets));
  });
});

SpecEnd
