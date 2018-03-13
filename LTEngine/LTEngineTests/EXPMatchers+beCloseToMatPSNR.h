// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

EXPMatcherInterface(_beCloseToMatPSNR, (NSValue *expected, id psnr));
EXPMatcherInterface(beCloseToMatPSNR, (NSValue *expected, id psnr));

/// Uses the given \c psnr as minimum allowed PSNR.
#define beCloseToMatPSNR(expected, psnr) _beCloseToMatPSNR((expected), EXPObjectify((psnr)))
