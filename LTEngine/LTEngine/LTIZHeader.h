// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Header of the ImageZero file format. All fields not specifically mentioned are little endian.
typedef struct __attribute__((packed)) {
  /// Must be \c kImageZeroHeaderSignature.
  uint16_t signature;
  /// Current version of the compressed image.
  uint16_t version;
  /// Number of channels of the image. Supported values are {1, 3}.
  uint16_t channels;
  /// Total width of the uncompressed image.
  uint16_t totalWidth;
  /// Total height of the uncompressed image.
  uint16_t totalHeight;
  /// Width of the current shard of the uncompressed image.
  uint16_t shardWidth;
  /// Height of the current shard of the uncompressed image.
  uint16_t shardHeight;
  /// Shard index of this archive.
  uint16_t shardIndex;
  /// Total number of shards that consist the compressed image.
  uint16_t shardCount;
} LTIZHeader;

/// ImageZero file header signature.
extern uint16_t kLTIZHeaderSignature;
