// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAppIntegrity.h"

#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <unordered_set>

#import "LTAppIntegrityInternal.h"
#import "LTMMInputFile.h"

NS_ASSUME_NONNULL_BEGIN

/// Decodes the given \c string.
static std::string LTDecodeString(const std::string_view &string);

#pragma mark -
#pragma mark Jailbreak Detection
#pragma mark -

BOOL LTIsJailbroken() {
#if TARGET_IPHONE_SIMULATOR
  return NO;
#else
  static const std::array<std::string_view, 4> kEncodedPaths{{
    // /bin/sh
    "(eni(to",
    // /bin/bash
    "(eni(efto",
    // /Applications/Cydia.app
    "(Fwwkndfsnhit(D~cnf)fww",
    // /Library/MobileSubstrate/MobileSubstrate.dylib
    "(Kneufu~(JhenkbTretsufsb(JhenkbTretsufsb)c~kne"
  }};

  for (const auto &path : kEncodedPaths) {
    auto decoded = LTDecodeString(path);
    int result = access(decoded.c_str(), R_OK);
    if (!result) {
      return YES;
    }
  }

  return NO;
#endif
}

#pragma mark -
#pragma mark Entitlements and Code Signing
#pragma mark -

// Since this is mostly based on undocumented binary info, please see the following refences for
// more information:
// 1. *OS Internals, Volume III, chapter 5 (Code Signing).
// 2. http://docs.macsysadmin.se/2017/pdf/Day4Session2.pdf
// 3. https://github.com/saucelabs/isign
// 4. https://davedelong.com/blog/2018/01/10/reading-your-own-entitlements

struct LTMachHeaderInfo {
  /// Memory mapped contents of the file that contains the header. The file is not accessed
  /// directly, but held here so that the object will not be deallocated and the file closed,
  /// rendering \c header invalid.
  LTMMInputFile * _Nullable file;
  /// Pointer to the mach header (which should be treated as mach_header_64 if \c is64Bit is
  /// \c true).
  const struct mach_header * _Nullable header;
  /// Indicates whether the \c header represents a 64-bit mach-o file.
  bool is64Bit;
};

/// Used to fetch information about the app's executable.
extern int main(int argc, char * _Nonnull argv[]);

static bool LTIsMachHeader64Bit(const struct mach_header *header) {
  return header->magic == MH_MAGIC_64 || header->magic == MH_CIGAM_64;
}

static bool LTIsMachHeader(uint32_t magic) {
  return magic == MH_MAGIC || magic == MH_MAGIC_64;
}

static uintptr_t LTGetPostHeaderPointer(const struct mach_header *header) {
  return (uintptr_t)header + (LTIsMachHeader64Bit(header) ? sizeof(mach_header_64) :
                              sizeof(mach_header));
}

static LTMachHeaderInfo LTGetExecutableMachHeaderInfo() {
  Dl_info dlinfo;

  if (!dladdr((void *)main, &dlinfo) || !dlinfo.dli_fname) {
    return {.file = nil, .header = nullptr, .is64Bit = false};
  }

  // The straightforward approach of using dli_fbase will not work in App Store builds, since the
  // loader doesn't load or strip the LINKEDIT information. Therefore, it seems that the only way to
  // access this data is to read the image from disk. Note that this increases the attack surface of
  // malicious code.
  auto _Nullable file = [[LTMMInputFile alloc] initWithPath:@(dlinfo.dli_fname) error:nil];
  if (!file || file.size < sizeof(uint32_t) || !LTIsMachHeader(*(uint32_t *)file.data)) {
    return {.file = nil, .header = nullptr, .is64Bit = false};
  }

  auto header = (const struct mach_header *)file.data;
  bool is64Bit = LTIsMachHeader64Bit(header);

  return {.file = file, .header = header, .is64Bit = is64Bit};
}

static const LTSuperBlob * _Nullable LTGetExecutableSuperBlob(const LTMachHeaderInfo &machInfo) {
  auto pointer = LTGetPostHeaderPointer((const struct mach_header *)machInfo.header);

  const struct linkedit_data_command *dataCommand = nullptr;
  for (uint32_t i = 0; i < machInfo.header->ncmds; ++i) {
    auto loadCommand = (const struct load_command *)pointer;
    if (loadCommand->cmd == LC_CODE_SIGNATURE) {
      dataCommand = (linkedit_data_command *)loadCommand;
      break;
    }
    pointer += loadCommand->cmdsize;
  }
  if (!dataCommand) {
    return nullptr;
  }

  auto superBlob = (const LTSuperBlob *)((uintptr_t)machInfo.header + dataCommand->dataoff);
  if (ntohl(superBlob->magic) != LT_MAGIC_EMBEDDED_SIGNATURE) {
    return nullptr;
  }

  return superBlob;
}

static const LTGenericBlob * _Nullable LTGetGenericBlob(const LTSuperBlob *superBlob,
                                                         uint32_t type, uint32_t magic) {
  const LTBlobIndex *limit = &superBlob->index[ntohl(superBlob->count)];
  for (const LTBlobIndex *index = superBlob->index; index < limit; ++index) {
    if (ntohl(index->type) != type) {
      continue;
    }

    auto blob = (const LTGenericBlob *)((uintptr_t)superBlob + ntohl(index->offset));
    if (ntohl(blob->magic) != magic) {
      return nullptr;
    }

    return blob;
  }

  return nullptr;
}

static NSString * _Nullable LTSigningTeamIdentifier(const LTSuperBlob *superBlob) {
  const LTCodeDirectory * _Nullable codeDirectory =
      (const LTCodeDirectory * _Nullable)LTGetGenericBlob(superBlob, LT_SLOT_CODEDIRECTORY,
                                                          LT_MAGIC_CODEDIRECTORY);
  if (!codeDirectory) {
    return nil;
  }

  // No team identifier in these code directory versions.
  if (ntohl(codeDirectory->version) < 0x20200) {
    return nil;
  }

  return @(((char *)codeDirectory) + ntohl(codeDirectory->teamOffset));
}

static NSDictionary<NSString *, id> * _Nullable LTPlistFromMemory(uintptr_t start,
                                                                  uint64_t length) {
  auto data = [NSData dataWithBytesNoCopy:(void *)start length:(NSUInteger)length freeWhenDone:NO];

  id _Nullable plist = [NSPropertyListSerialization propertyListWithData:data
                                                                 options:NSPropertyListImmutable
                                                                  format:nil error:nil];
  if (![plist isKindOfClass:[NSDictionary class]]) {
    return nil;
  }

  return plist;
}

static __unused NSDictionary<NSString *, id> * _Nullable
    LTAppEntitlementsFromSuperBlob(const LTSuperBlob *superBlob) {
  auto genericBlob =
      (const LTGenericBlob * _Nullable)LTGetGenericBlob(superBlob, LT_SLOT_ENTITLEMENTS,
                                                        LT_MAGIC_EMBEDDED_ENTITLEMENTS);
  if (!genericBlob) {
    return nil;
  }

  return LTPlistFromMemory((uintptr_t)genericBlob->data,
                           ntohl(genericBlob->length) - sizeof(LTGenericBlob));
}

static __unused NSDictionary<NSString *, id> * _Nullable
    LTAppEntitlementsFromTextSegment(const LTMachHeaderInfo &machInfo) {
  // __TEXT
  auto segmentName = LTDecodeString("XXSB_S");
  // __entitlements
  auto sectionName = LTDecodeString("XXbisnskbjbist");

  uint32_t dataOffset;
  uint64_t dataLength;

  if (machInfo.is64Bit) {
    const struct section_64 * _Nullable section =
        getsectbynamefromheader_64((const struct mach_header_64 *)machInfo.header,
                                   segmentName.c_str(), sectionName.c_str());
    if (!section) {
      return nullptr;
    }

    dataOffset = section->offset;
    dataLength = section->size;
  } else {
    const struct section * _Nullable section = getsectbynamefromheader(machInfo.header,
                                                                       segmentName.c_str(),
                                                                       sectionName.c_str());
    if (!section) {
      return nullptr;
    }

    dataOffset = section->offset;
    dataLength = section->size;
  }

  return LTPlistFromMemory((uintptr_t)machInfo.header + dataOffset, dataLength);
}

NSString * _Nullable LTSigningTeamIdentifier() {
  auto machInfo = LTGetExecutableMachHeaderInfo();
  if (!machInfo.header) {
    return nil;
  }
  auto superBlob = LTGetExecutableSuperBlob(machInfo);
  return superBlob ? LTSigningTeamIdentifier(superBlob) : nil;
}

NSDictionary<NSString *, id> * _Nullable LTAppEntitlements() {
  auto machInfo = LTGetExecutableMachHeaderInfo();
  if (!machInfo.header) {
    return nil;
  }
#if !TARGET_OS_SIMULATOR && TARGET_OS_IPHONE
  auto superBlob = LTGetExecutableSuperBlob(machInfo);
  return superBlob ? LTAppEntitlementsFromSuperBlob(superBlob) : nil;
#else
  return LTAppEntitlementsFromTextSegment(machInfo);
#endif
}

#pragma mark -
#pragma mark Hijack Detection
#pragma mark -

/// Defines a memory address range of a segment.
struct LTSegmentInfo {
  /// Constructs a new segment info. Used for emplacing the struct directly into a vector.
  LTSegmentInfo(uint64_t start, uint64_t length) : start(start), length(length) {};

  /// Start of the range.
  uint64_t start;

  /// Length of the range.
  uint64_t length;
};

/// Returns a map between the image name and its slide, which is the offset in virtual memory the
/// image data starts from.
static auto LTGetImageNameToSlide() {
  std::map<std::string, uint64_t> imageNameToSlide;
  for (uint32_t i = 0; i < _dyld_image_count(); ++i) {
    imageNameToSlide[_dyld_get_image_name(i)] = _dyld_get_image_vmaddr_slide(i);
  }
  return imageNameToSlide;
}

/// Returns a map between a memory segment and the image that mapped the segment.
static auto LTGetSegments(const std::unordered_set<std::string> &imagesToExclude) {
  std::vector<LTSegmentInfo> segments;

  auto slides = LTGetImageNameToSlide();

  for (uint32_t i = 0; i < _dyld_image_count(); ++i) {
    const char *imageName = _dyld_get_image_name(i);
    if (imagesToExclude.count(imageName)) {
      continue;
    }

    auto header = (const struct mach_header *)_dyld_get_image_header(i);
    auto pointer = LTGetPostHeaderPointer(header);

    for (uint32_t j = 0; j < header->ncmds; ++j) {
      auto loadCommand = (const struct load_command *)pointer;
      if (loadCommand->cmd == LC_SEGMENT) {
        struct segment_command *segmentCommand = (struct segment_command *)loadCommand;
        segments.emplace_back(
          segmentCommand->vmaddr + slides[imageName],
          segmentCommand->vmsize
        );
      } else if (loadCommand->cmd == LC_SEGMENT_64) {
        struct segment_command_64 *segmentCommand = (struct segment_command_64 *)loadCommand;
        segments.emplace_back(
          segmentCommand->vmaddr + slides[imageName],
          segmentCommand->vmsize
        );
      }

      pointer += loadCommand->cmdsize;
    }
  }

  return segments;
}

/// Returns the path of the executable. This is not guaranteed to be the real path to the
/// executable. For example, it can return a path to a symlink to it.
static NSString * _Nullable LTGetExecutablePath() {
  uint32_t bufSize = 0;

  int result = _NSGetExecutablePath(nullptr, &bufSize);
  if (result != -1) {
    return nil;
  }

  auto path = std::make_unique<char[]>(bufSize);
  result = _NSGetExecutablePath(path.get(), &bufSize);
  if (result) {
    return nil;
  }

  return @(path.get());
}

/// Returns all the images under the executable's directory.
static std::unordered_set<std::string> LTGetImagesUnderExecutableDirectory() {
  auto directory = LTGetExecutablePath().stringByDeletingLastPathComponent;
  if (!directory) {
    return {};
  }

  std::unordered_set<std::string> images;
  for (uint32_t i = 0; i < _dyld_image_count(); ++i) {
    NSString *imageName = @(_dyld_get_image_name(i));
    if ([imageName hasPrefix:directory]) {
      images.emplace(_dyld_get_image_name(i));
    }
  }

  return images;
}

/// Called with each \c classObject found by \c LTIterateClassesForImage.
typedef void (^LTClassIterationBlock)(Class _Nullable __unsafe_unretained classObject);

/// Calls \c block for every class that is defined in \c image.
static void LTIterateClassesForImage(const char *image, LTClassIterationBlock block) {
  unsigned int classCount;
  auto classes = objc_copyClassNamesForImage(image, &classCount);
  for (unsigned int i = 0; i < classCount; ++i) {
    block(objc_getClass(classes[i]));
  }
  free(classes);
}

/// Called for each \c method found by \c LTIterateInstanceMethods.
typedef void (^LTMethodIterationBlock)(Method method);

/// Calls \c block for every instance method of \c classObject.
static void LTIterateInstanceMethods(Class classObject, LTMethodIterationBlock block) {
  unsigned int methodCount;
  Method *methods = class_copyMethodList(classObject, &methodCount);
  for (unsigned int i = 0; i < methodCount; ++i) {
    block(methods[i]);
  }
  free(methods);
}

/// Calls \c block for every class and instance method of \c classObject.
static void LTIterateMethods(Class classObject, LTMethodIterationBlock block) {
  Class _Nullable metaClass = objc_getMetaClass(class_getName(classObject));
  if (metaClass) {
    LTIterateInstanceMethods(nn(metaClass), block);
  }
  LTIterateInstanceMethods(classObject, block);
}

std::vector<LTHijackedMethodInfo> LTHijackedMethods() {
  auto images = LTGetImagesUnderExecutableDirectory();
  auto segments = LTGetSegments(images);

  auto compare = [](const LTSegmentInfo &a, const LTSegmentInfo &b) {
    return a.start < b.start;
  };
  std::sort(segments.begin(), segments.end(), compare);

  __block std::vector<LTHijackedMethodInfo> info;
  for (auto image : images) {
    LTIterateClassesForImage(image.c_str(), ^(Class classObject) {
      LTIterateMethods(classObject, ^(Method method) {
        IMP imp = method_getImplementation(method);
        uint64_t address = (uint64_t)imp;
        LTSegmentInfo range(address, 0);

        auto it = std::upper_bound(segments.cbegin(), segments.cend(), range, compare);
        if (it == segments.cbegin()) {
          return;
        }

        it = std::prev(it);
        do {
          if (address <= it->start + it->length) {
            std::string targetImage;
            std::string targetMethod;

            Dl_info loaderInfo;
            int result = dladdr((const void *)imp, &loaderInfo);
            if (result) {
              targetImage = loaderInfo.dli_fname;
              targetMethod = loaderInfo.dli_sname;
            }

            info.push_back({
              .sourceImage = std::string(image),
              .sourceMethod = sel_getName(method_getName(method)),
              .targetImage = targetImage,
              .targetMethod = targetMethod
            });
          }

          ++it;
        } while (it != segments.cend() && it->start <= address);
      });
    });
  }

  return info;
}

#pragma mark -
#pragma mark Utilities
#pragma mark -

static std::string LTDecodeString(const std::string_view &string) {
  static const char kKey = 0x7;

  std::string result;
  for (char c : string) {
    result.push_back(c ^ kKey);
  }

  return result;
}

NS_ASSUME_NONNULL_END
