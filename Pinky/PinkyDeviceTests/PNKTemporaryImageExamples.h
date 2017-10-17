// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

/// Group name of shared tests for \c PNKUnaryKernel implementations that support
/// \c MPSTemporaryImage as inputs to their encode methods. The shared tests check whether the
/// kernels manage the \c readCount property correctly by decreasing it after encoding the image.
extern NSString * const kPNKTemporaryImageUnaryExamples;

/// Group name of shared tests for \c PNKBinaryKernel implementations that support
/// \c MPSTemporaryImage as inputs to their encode methods. The shared tests check whether the
/// kernels manage the \c readCount property correctly by decreasing it after encoding the image.
extern NSString * const kPNKTemporaryImageBinaryExamples;

/// Dictionary key to the object whose implementation of the \c PNKUnaryKernel or \c PNKBinaryKernel
/// protocol is to test.
extern NSString * const kPNKTemporaryImageExamplesKernel;

/// Dictionary key to the \c MTLDevice used to create the kernel to be tested.
extern NSString * const kPNKTemporaryImageExamplesDevice;

/// Dictionary key stating if the input image is a texture array.
extern NSString * const kPNKTemporaryImageExamplesIsArray;
