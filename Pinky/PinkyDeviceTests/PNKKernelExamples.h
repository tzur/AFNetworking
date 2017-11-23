// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

/// Group name of shared tests for \c PNKUnaryKernel implementations checking that the encoded
/// operation completes successfully and that the output is correct.
extern NSString * const kPNKUnaryKernelExamples;

/// Group name of shared tests for \c PNKBinaryKernel implementations checking that the encoded
/// operation completes successfully and that the output is correct.
extern NSString * const kPNKBinaryKernelExamples;

/// Group name of shared tests for \c PNKBinaryImageKernel implementations checking that the encoded
/// operation completes successfully and that the output is correct.
extern NSString * const kPNKBinaryImageKernelExamples;

/// Dictionary key to the object whose implementation of the \c PNKUnaryKernel or \c PNKBinaryKernel
/// protocol is to test.
extern NSString * const kPNKKernelExamplesKernel;

/// Dictionary key to the \c MTLDevice used to create the kernel to be tested.
extern NSString * const kPNKKernelExamplesDevice;

/// Dictionary key stating the pixel format of the images.
extern NSString * const kPNKKernelExamplesPixelFormat;

/// Dictionary key stating the number of primary input channels.
extern NSString * const kPNKKernelExamplesPrimaryInputChannels;

/// Dictionary key stating the number of secondary input channels.
extern NSString * const kPNKKernelExamplesSecondaryInputChannels;

/// Dictionary key stating the number of input channels.
extern NSString * const kPNKKernelExamplesOutputChannels;

/// Dictionary key stating the width of the output image.
extern NSString * const kPNKKernelExamplesOutputWidth;

/// Dictionary key stating the height of the output image.
extern NSString * const kPNKKernelExamplesOutputHeight;

/// Dictionary key to the cv::Mat representing the primary input image.
extern NSString * const kPNKKernelExamplesPrimaryInputMat;

/// Dictionary key to the cv::Mat representing the secondary input image.
extern NSString * const kPNKKernelExamplesSecondaryInputMat;

/// Dictionary key to the cv::Mat representing the expected result image.
extern NSString * const kPNKKernelExamplesExpectedMat;
