# Pinky - library of essential Metal compute cores with strong emphasis on neural networks

## Important functionality

1. Network layers - building blocks for CNNs.
2. Neural Networks - fully built CNNs.
3. Processors - ready-to-use CNNs (with pre- and post- processing).
4. Image Processing - other image processing algorithms.

## Before you start

1. Pinky runs on iOS 10 and up only (best results are shown on iOS 11).
2. Pinky does not support GPU family 1. To check if it runs on the current device please call `PNKSupportsMTLDevice` before calling any other Pinky API.
3. Pinky does not run on simulators. To prevent your Pinky-calling code from being compiled on simulators - wrap it in `#if PNK_USE_MPS ... #endif` macro and include "PNKDefines.h" that defines this macro.