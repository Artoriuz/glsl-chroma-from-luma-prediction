# GLSL Chroma from Luma (CfL) Prediction

## Overview
The shaders implement chroma upscaling based on the closed least squares solution for linear regression, [inspired by the adoption of the same technique in modern video codecs](https://arxiv.org/abs/1711.03951).
Since a simple linear regression obviously doesn't take into account pixel distance, the prediction is mixed with the output of a normal resampling filter based on how high the correlation between luma and chroma is.

The repo contains 3 variants of the shader:
- `CfL_Prediction.glsl`: Main variant, attempts to recreate as much detail as possible without introducing too many artifacts. 
- `CfL_Prediction_4tap.glsl`: A more aggressive variant that only uses the 4 nearest data pairs in its linear regression. Can sometimes produce better fine detail but it's also much less stable (more artifacts).
- `CfL_Prediction_12tap.glsl`: A less aggressive variant without the smaller linear regression at all. This is the safest option if you want to avoid the worst artifacts, but it can also look a bit softer sometimes.

The shaders are experimental and minor improvements are being made over time. If you have any suggestions, feel free to send them.

## Instructions
Add something like this to your mpv config:
```
glsl-shader="path/to/shader/CfL_Prediction.glsl"
```
