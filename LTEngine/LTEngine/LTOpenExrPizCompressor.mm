// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTOpenExrPizCompressor.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/LTMMOutputFile.h>
#import <OpenEXR/ImfIO.h>
#import <OpenEXR/ImfRgbaFile.h>

#import "LTOpenCVHalfFloat.h"

NS_ASSUME_NONNULL_BEGIN

namespace Imf {

/// Wrapper for NSError* to be thrown and catched in C++ code.
class ObjcRuntimeException : public std::exception {
public:
  /// Instantiates a new Objective-C Runtime Exception with an NSError object.
  explicit ObjcRuntimeException(NSError *error) : std::exception(), _error(error) {
  }

  /// Gets the wrapped NSError object.
  NSError *error() const {
    return _error;
  }

private:
  /// NSError instance.
  NSError *_error;
};

/// Memory-mapped input stream for reading OpenEXR compressed data.
class MemoryMappedInputStream : public IStream {
public:
  /// Instantiates a new memory-mapped input stream for reading from the file specified by
  /// \c filePath. If such file does not exist, an \c NSInvalidArgumentException is raised.
  explicit MemoryMappedInputStream(const char *filePath) : IStream(filePath), _pos(0) {
    NSString *pathString = [NSString stringWithUTF8String:filePath];
    NSError *error;

    _inputFile = [[LTMMInputFile alloc] initWithPath:pathString error:&error];
    if (!_inputFile) {
      throw ObjcRuntimeException(error);
    }

    _data = _inputFile.data;
    _size = _inputFile.size;
  }

  /// Marks this stream as memory mapped.
  virtual bool isMemoryMapped() const {
    return YES;
  }

  /// Reads \c count bytes from the stream and copies them into the \c buffer. If
  /// <tt>read(buffer, count)</tt> reads the last byte from the stream it returns \c false,
  /// otherwise it returns \c true. If there are less than \c count bytes left to read from the
  /// stream, \c NSInvalidArgumentException is raised. If \c count is negative,
  /// \c NSInvalidArgumentException is raised.
  virtual bool read(char *buffer, int count) {
    LTParameterAssert(count >= 0, @"Negative count of bytes to read: %d", count);
    LTParameterAssert(_pos + count <= _size, @"Attempt to read from position %lu in file of size "
                      "%lu", (unsigned long)_pos + count, _size);

    memcpy(buffer, _data + _pos, count);
    _pos += count;

    return _pos != _size;
  }

  /// Reads \c count bytes from the (memory-mapped) stream and returns the pointer to the first
  /// byte. The returned pointer remains valid until the stream is closed. If there are less than
  /// \c count bytes left to read from the stream, \c NSInvalidArgumentException is raised. If
  /// \c count is negative, \c NSInvalidArgumentException is raised.
  virtual char *readMemoryMapped(int count) {
    LTParameterAssert(count >= 0, @"Negative count of bytes to read: %d", count);
    LTParameterAssert(_pos + count <= _size, @"Attempt to read from position %lu in file of size "
                      "%lu", (unsigned long)_pos + count, _size);

    char *result = (char *)(_data + _pos);
    _pos += count;
    return result;
  }

  /// Gets the current reading position.
  virtual Int64 tellg() {
    return _pos;
  }

  /// Set the current reading position (for random access). If \c pos is greater than the file size,
  /// \c NSInvalidArgumentException is raised.  If \c pos is negative, \c NSInvalidArgumentException
  /// is raised.
  virtual void seekg(Int64 pos) {
    LTParameterAssert(pos >= 0 && pos <= _size, @"Attempt to set read position to %lu in file of "
                      "size %ld", (unsigned long)pos, _size);
    _pos = pos;
  }

private:
  /// Memory-mapped input file object.
  LTMMInputFile *_inputFile;

  /// Size of the memory buffer - equals the size of the file.
  size_t _size;

  /// Current position in the stream.
  Int64 _pos;

  /// The memory buffer.
  const uint8_t *_data;
};

/// Memory-mapped output stream for writing OpenEXR compressed data.
class MemoryMappedOutputStream : public OStream {
public:
  /// Instantiates a new memory-mapped stream with the given file path, capacity and attributes.
  /// If the OS fails to create the file or to allocate memory for the underlying buffer -
  /// \c NSInvalidArgumentException is raised.
  MemoryMappedOutputStream(const char *filePath, size_t capacity, mode_t mode) : OStream(filePath),
      _capacity(capacity), _size(0), _pos(0) {
    NSString *pathString = [NSString stringWithUTF8String:filePath];
    NSError *error;

    _outputFile = [[LTMMOutputFile alloc] initWithPath:pathString size:capacity mode:mode
                                                 error:&error];
    if (!_outputFile) {
      throw ObjcRuntimeException(error);
    }

    _data = _outputFile.data;
  }

  /// Starts writing the data to the file, then destructs the object. The write operation will be
  /// finished by OS after the object has been destructed.
  virtual ~MemoryMappedOutputStream() {
    _outputFile.finalSize = _size;
  }

  /// Writes \c count characters from \c buffer into the stream, updates the current position. If
  /// the new position would exceed the stream capacity - \c NSInvalidArgumentException is raised.
  /// If \c count is negative - \c NSInvalidArgumentException is raised.
  virtual void write(const char *buffer, int count) {
    LTParameterAssert(count >= 0, @"Negative count of bytes to write: %d", count);
    LTParameterAssert(_pos + count <= _capacity, @"Attempt to write to position %lu in stream of "
                      "capacity %lu", (unsigned long)_pos + count, _capacity);

    memcpy(_data + _pos, buffer, count);
    _pos += count;
    _size = std::max(_size, (size_t)_pos);
  }

  /// Retrieves the current position in the stream.
  virtual Int64 tellp() {
    return _pos;
  }

  /// Sets the current position in the stream (for random access). If \c pos is greater than stream
  /// capacity - \c NSInvalidArgumentException is raised. If \c pos is negative -
  /// \c NSInvalidArgumentException is raised.
  virtual void seekp(Int64 pos) {
    LTParameterAssert(pos >= 0 && pos <= _capacity, @"Invalid position %ld in file of size %ld",
                      (unsigned long)pos, _capacity);
    _pos = pos;
  }

private:
  /// Memory-mapped output file object.
  LTMMOutputFile *_outputFile;

  /// Stream capacity - size of the underlying memory buffer.
  size_t _capacity;

  /// Size of the actually used part of the memory buffer.
  size_t _size;

  /// Current position in the stream.
  Int64 _pos;

  /// The memory buffer.
  uint8_t *_data;
};

/// Output stream that only counts written characters - without saving them.
class CharacterCountingOutputStream : public OStream {
public:
  /// Instantiates a new character counting output stream.
  CharacterCountingOutputStream() : OStream(""), _size(0), _pos(0) {
  }

  /// Update the current position and size of the stream as if \c count characters were written.
  virtual void write(const char *, int count) {
    _pos += count;
    _size = std::max(_size, _pos);
  }

  /// Sets the current position in the stream.
  virtual void seekp(Int64 pos) {
    _pos = pos;
  }

  /// Retrieves the current position in the stream.
  virtual Int64 tellp() {
    return _pos;
  }

  /// Retrieves the current size of the stream.
  Int64 size() {
    return _size;
  }

private:
  /// Size of the buffer that should be reserved for actually writing the data.
  Int64 _size;

  /// Current position in the stream.
  Int64 _pos;
};

}  // namespace Imf

@implementation LTOpenExrPizCompressor

- (instancetype)init {
  if (self = [super init]) {
    [self.class configureGlobalThreadCount];
  }
  return self;
}

+ (void)configureGlobalThreadCount {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    int coreCount = (int)[[NSProcessInfo processInfo] activeProcessorCount];
    Imf::setGlobalThreadCount(coreCount);
  });
}

- (BOOL)compressImage:(const cv::Mat &)image toPath:(NSString *)path
                error:(NSError *__autoreleasing *)error {
  [self verifyImageTypeAndSize:image];

  Imf::Header rgbaOutputFileHeader(image.cols, image.rows, 1, Imath::V2f(0, 0), 1,
                                   Imf::INCREASING_Y, Imf::PIZ_COMPRESSION);

  // Measure the header size by "writing" it to a character-counting stream.
  Imf::CharacterCountingOutputStream characterCountingOutputStream;
  rgbaOutputFileHeader.writeTo(characterCountingOutputStream);
  NSUInteger headerSize = (NSUInteger)characterCountingOutputStream.size();

  // Upper bound on the Huffman table size.
  static const NSUInteger kHuffmanTableMaxSize = (1 << 16) * sizeof(Imf::Int64);

  // Number of chunks. Chunks are 128 pixel high horizontal strips (the constant 128 is hard-coded
  // in OpenEXR). Each chunk has its own Huffman table.
  NSUInteger chunks = (image.rows - 1) / 128 + 1;

  // Upper bound on the total size of all Huffman tables.
  NSUInteger allHuffmanTablesMaxSize = chunks * kHuffmanTableMaxSize;

  // Upper bound on the compressed file size. We assume here that Huffman-compressed data size (not
  // including the codes table) never exceeds the source data size.
  size_t streamCapacity = headerSize + allHuffmanTablesMaxSize +
      image.total() * image.elemSize();

  std::unique_ptr<Imf::MemoryMappedOutputStream> compressedDataStream;
  try {
    compressedDataStream =
        std::make_unique<Imf::MemoryMappedOutputStream>(path.UTF8String, streamCapacity, 0644);
  } catch (const Imf::ObjcRuntimeException &exception) {
    if (error) {
      *error = exception.error();
    }
    return NO;
  }
  Imf::RgbaOutputFile file(*compressedDataStream, rgbaOutputFileHeader);

  file.setFrameBuffer((Imf::Rgba *)image.data, 1, image.step1() / image.channels());
  file.writePixels(image.rows);
  return YES;
}

- (BOOL)decompressFromPath:(NSString *)path toImage:(cv::Mat *)image
                     error:(NSError *__autoreleasing *)error {
  [self verifyImageTypeAndSize:*image];

  std::unique_ptr<Imf::MemoryMappedInputStream> inputDataStream;
  try {
    inputDataStream = std::make_unique<Imf::MemoryMappedInputStream>(path.UTF8String);
  } catch (const Imf::ObjcRuntimeException &exception) {
    if (error) {
      *error = exception.error();
    }
    return NO;
  }

  Imf::RgbaInputFile rgbaInputFile(*inputDataStream);

  if (![self verifyRgbaInputFile:rgbaInputFile withImageSize:image->size() error:error]) {
    return NO;
  }

  Imath::Box2i dataWindow = rgbaInputFile.dataWindow();

  rgbaInputFile.setFrameBuffer((Imf::Rgba *)image->data, 1, image->step1() / image->channels());
  rgbaInputFile.readPixels(dataWindow.min.y, dataWindow.max.y);

  if (!rgbaInputFile.isComplete()) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed
                             description:@"Error while decompressing OpenEXR PIZ data"];
    }
    return NO;
  }

  return YES;
}

- (void)verifyImageTypeAndSize:(const cv::Mat &)image {
  LTParameterAssert(image.type() == CV_16FC4, @"Given image type must be equal to CV_16FC4(%d). Got"
                    "image with type %d", CV_16FC4, image.type());
  LTParameterAssert(image.cols != 0, @"Given image has 0 columns");
  LTParameterAssert(image.rows != 0, @"Given image has 0 rows");
}

- (BOOL)verifyRgbaInputFile:(const Imf::RgbaInputFile &)rgbaInputFile
              withImageSize:(cv::Size)imageSize error:(NSError *__autoreleasing *)error {
  Imath::Box2i dataWindow = rgbaInputFile.dataWindow();
  int width = dataWindow.max.x - dataWindow.min.x + 1;
  int height = dataWindow.max.y - dataWindow.min.y + 1;

  if (imageSize.width != width || imageSize.height != height) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed description:@"Given image size "
                "must be equal to the compressed image's size. Got image with size (%d, %d), where "
                "the compressed image size is (%d, %d)", imageSize.width, imageSize.height, width,
                height];
    }
    return NO;
  }

  return YES;
}

@end

NS_ASSUME_NONNULL_END
