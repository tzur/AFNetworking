// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#ifndef Pinky_PNKTEMPLATEDIO_METAL_
#define Pinky_PNKTEMPLATEDIO_METAL_

#include <metal_stdlib>

using namespace metal;

namespace lt {
  template <typename T, access a>
  vec<T, 4> read(texture2d<T, a> texture, ushort2 coord, ushort array = 0, ushort lod = 0) {
    return texture.read(coord, lod);
  }

  template <typename T, access a>
  vec<T, 4> read(texture2d<T, a> texture, uint2 coord, uint array = 0, uint lod = 0) {
    return texture.read(coord, lod);
  }

  template <typename T, access a>
  vec<T, 4> read(texture2d_array<T, a> texture, ushort2 coord, ushort array = 0, ushort lod = 0) {
    return texture.read(coord, array, lod);
  }

  template <typename T, access a>
  vec<T, 4> read(texture2d_array<T, a> texture, uint2 coord, uint array = 0, uint lod = 0) {
    return texture.read(coord, array, lod);
  }

  template <typename T>
  vec<T, 4> sample(texture2d<T, access::sample> texture, sampler s, float2 coord,
                   ushort array = 0) {
    return texture.sample(s, coord);
  }

  template <typename T>
  vec<T, 4> sample(texture2d<T, access::sample> texture, sampler s, float2 coord, uint array = 0) {
    return texture.sample(s, coord);
  }

  template <typename T>
  vec<T, 4> sample(texture2d_array<T, access::sample> texture, sampler s, float2 coord,
                   ushort array = 0) {
    return texture.sample(s, coord, array);
  }

  template <typename T>
  vec<T, 4> sample(texture2d_array<T, access::sample> texture, sampler s, float2 coord,
                   uint array = 0) {
    return texture.sample(s, coord, array);
  }

  template <typename T, access a>
  void write(texture2d<T, a> texture, vec<T, 4> value, ushort2 coord, ushort array = 0,
             ushort lod = 0) {
    texture.write(value, coord, lod);
  }

  template <typename T, access a>
  void write(texture2d<T, a> texture, vec<T, 4> value, uint2 coord, uint array = 0,
             uint lod = 0) {
    texture.write(value, coord, lod);
  }

  template <typename T, access a>
  void write(texture2d_array<T, a> texture, vec<T, 4> value, ushort2 coord, ushort array = 0,
             ushort lod = 0) {
    texture.write(value, coord, array, lod);
  }

  template <typename T, access a>
  void write(texture2d_array<T, a> texture, vec<T, 4> value, uint2 coord, uint array = 0,
             uint lod = 0) {
    texture.write(value, coord, array, lod);
  }
}

#endif // Pinky_PNKTEMPLATEDIO_METAL_
