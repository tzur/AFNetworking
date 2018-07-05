// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Is assumed to be orthographic projection.
uniform highp mat4 projection;

/// Model view matrix for converting object space coordinates into model-view coordinates.
uniform highp mat4 modelview;

/// Texture sampled at the center of the rendered quad, if \c sampleUniformColorFromColorTexture is
/// \c YES. Assumed to be non-premultiplied if \c colorTextureIsNonPremultiplied is \c YES.
uniform mediump sampler2D colorTexture;
uniform bool colorTextureIsNonPremultiplied;
uniform bool sampleUniformColorFromColorTexture;

/// RGB or RGBA texture, in non-premultiplied or premultiplied format, used for computing the edges
/// potentially restricting the rendering.
uniform mediump sampler2D edgeAvoidanceGuideTexture;

/// Additive offset, in object space coordinates, used to compute the locations at which the
/// \c edgeAvoidanceGuideTexture is sampled.
uniform highp vec2 edgeAvoidanceSamplingOffset;

/// Vertices, in homogeneous object space coordinates, of the rendered quad.
attribute highp vec4 position;
attribute highp vec3 texcoord;

/// Center, in non-homogeneous XY object space coordinates, of the rendered quad.
attribute highp vec2 quadCenter;

/// Red component of RGB color, in non-premultiplied unnormalized byte format, forwarded to the
/// fragment shader, in case that \c sampleUniformColorFromColorTexture is \c YES.
attribute highp float colorRed;

/// Green component of RGB color, in non-premultiplied unnormalized byte format, forwarded to the
/// fragment shader, in case that \c sampleUniformColorFromColorTexture is \c YES.
attribute highp float colorGreen;

/// Blue component of RGB color, in non-premultiplied unnormalized byte format, forwarded to the
/// fragment shader, in case that \c sampleUniformColorFromColorTexture is \c YES.
attribute highp float colorBlue;

varying highp vec4 vPosition;
varying highp vec3 vTexcoord;
varying highp vec3 vSampledColor0;
varying highp vec3 vSampledColor1;
varying highp vec3 vSampledColor2;
varying highp vec3 vSampledColor3;
varying highp vec3 vSampledColor4;

/// RGBA color, in premultiplied format, forwarded to the fragment shader.
varying highp vec4 vPremultipliedColor;

mediump vec4 premultipliedColor(in mediump vec4 nonPremultipliedColor) {
  return vec4(nonPremultipliedColor.rgb * nonPremultipliedColor.a, nonPremultipliedColor.a);
}

highp vec2 sampleLocationWithOffset(highp vec2 offset) {
  highp vec4 homogeneousLocation = modelview * vec4(quadCenter + offset, 0.0, 1.0);
  return vec2(homogeneousLocation.x / homogeneousLocation.w,
              homogeneousLocation.y / homogeneousLocation.w);
}

void main() {
  vPremultipliedColor = vec4(colorRed, colorGreen, colorBlue, 1.0);

  if (sampleUniformColorFromColorTexture) {
    if (colorTextureIsNonPremultiplied) {
      vPremultipliedColor *=
          premultipliedColor(texture2D(colorTexture, sampleLocationWithOffset(vec2(0.0))));
    } else {
      vPremultipliedColor *= texture2D(colorTexture, sampleLocationWithOffset(vec2(0.0)));
    }
  }

  highp vec4 modelviewPosition = modelview * vec4(position.x, position.y, 0, position.w);
  vPosition = modelviewPosition;
  vTexcoord = texcoord;

  vSampledColor0 = texture2D(edgeAvoidanceGuideTexture, sampleLocationWithOffset(vec2(0.0))).rgb;
  vSampledColor1 =
      texture2D(edgeAvoidanceGuideTexture,
                sampleLocationWithOffset(vec2(0.0, 1.0) * edgeAvoidanceSamplingOffset)).rgb;
  vSampledColor2 =
      texture2D(edgeAvoidanceGuideTexture,
                sampleLocationWithOffset(vec2(0.0, -1.0) * edgeAvoidanceSamplingOffset)).rgb;
  vSampledColor3 =
      texture2D(edgeAvoidanceGuideTexture,
                sampleLocationWithOffset(vec2(1.0, 0.0) * edgeAvoidanceSamplingOffset)).rgb;
  vSampledColor4 =
      texture2D(edgeAvoidanceGuideTexture,
                sampleLocationWithOffset(vec2(-1.0, 0.0) * edgeAvoidanceSamplingOffset)).rgb;
  gl_Position = projection * modelviewPosition;
}
