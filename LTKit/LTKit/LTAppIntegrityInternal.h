// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Blobs magics.
enum {
  LT_MAGIC_CODEDIRECTORY = 0xfade0c02,
  LT_MAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0,
  LT_MAGIC_EMBEDDED_ENTITLEMENTS = 0xfade7171
};

/// Slot indices.
enum {
  LT_SLOT_CODEDIRECTORY = 0,
  LT_SLOT_ENTITLEMENTS = 5
};

typedef struct {
  /// Magic (CS_CODEDIRECTORY).
  uint32_t magic;
  /// Total length of the blob.
  uint32_t length;
  /// Compatibility version.
  uint32_t version;
  /// Setup and mode flags.
  uint32_t flags;
  /// Offset of hash at index 0.
  uint32_t hashOffset;
  /// Offset of identifier string.
  uint32_t identOffset;
  /// Special hash slots count.
  uint32_t specialSlotsCount;
  /// Regular code slots count.
  uint32_t codeSlotsCount;
  /// Limit to main image signature range.
  uint32_t codeLimit;
  /// Size of each hash in bytes.
  uint8_t hashSize;
  /// Type of hash.
  uint8_t hashType;
  /// Platform identifier.
  uint8_t platform;
  /// log of page size in bytes.
  uint8_t pageSize;
  /// Unused (zeroes).
  uint32_t unused;
  char endEarliest[0];

  // Version 0x20100.

  /// Offset of optional scatter vector.
  uint32_t scatterOffset;
  char endWithScatter[0];

  // Version 0x20200.

  /// Offset of optional team identifier.
  uint32_t teamOffset;
  char endWithTeam[0];

  // Version 0x20300.

  /// Unused (zeros).
  uint32_t unused2;
  // Limit to main image signature range.
  uint64_t codeLimit64;
  char endWithCodeLimit64[0];

  // Version 0x20400.

  /// Offset of executable segment.
  uint64_t execSegBase;
  /// Limit of executable segment.
  uint64_t execSegLimit;
  /// Executable segment flags.
  uint64_t execSegFlags;
  char endWithExecSeg[0];

  // Followed by dynamic content defined by the fields above.
} LTCodeDirectory __attribute__((aligned(1)));

typedef struct {
  /// Type of entry.
  uint32_t type;
  /// Entry offset.
  uint32_t offset;
} LTBlobIndex __attribute__((aligned(1)));

typedef struct {
  /// Magic.
  uint32_t magic;
  /// Length of the superblob.
  uint32_t length;
  /// Number of index entries.
  uint32_t count;
  /// \c count entries.
  LTBlobIndex index[];

  // Followed by blobs.
} LTSuperBlob __attribute__((aligned(1)));

typedef struct {
  /// Magic.
  uint32_t magic;
  /// Total legnth of blob.
  uint32_t length;
  /// Data held by the blob.
  char data[];
} LTGenericBlob __attribute__((aligned(1)));
