# GLSL Chroma from Luma (CfL) Prediction

## Overview
The shaders implement chroma upscaling based on the closed least squares solution for linear regression, [inspired by the adoption of the same technique in modern video codecs](https://arxiv.org/abs/1711.03951).
Since a simple linear regression obviously doesn't take into account pixel distance, the prediction is mixed with the output of a normal resampling filter based on how high the correlation between luma and chroma is.

You can control which local linear regressions you want to use with `USE_12_TAP_REGRESSION`,  `USE_8_TAP_REGRESSIONS`.

The lite variant offers better performance at the expense of some quality. Dev variant has a bilateral smoothing filter applied as a third step to remove most artifacts created by the shader.

## Instructions
Add something like this to your mpv config:
```
glsl-shader="path/to/shader/CfL_Prediction.glsl"
```
