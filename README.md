# GLSL Chroma from Luma (CfL) Prediction

## Overview
The shaders implement chroma upscaling based on the closed least squares solution for linear regression, [inspired by the adoption of the same technique in modern video codecs](https://arxiv.org/abs/1711.03951).
Since a simple linear regression obviously doesn't take into account pixel distance, the prediction is mixed with the output of a normal resampling filter based on how high the correlation between luma and chroma is.

The repo contains 3 variants of the shader:
- `CfL_Prediction.glsl`: Main variant, attempts to recreate as much detail as possible without introducing too many artifacts. You can disable the 4-tap regression with `USE_4_TAP_REGRESSION 0` to reduce the amount of artifacts created by the shader, although it'll also make it softer.
- `CfL_Prediction_4tap.glsl`: A more aggressive variant that only uses the 4 nearest data pairs in its linear regression. Can sometimes produce better fine detail but it's also much less stable (more artifacts).

The shaders are experimental and minor improvements are being made over time. If you have any suggestions, feel free to send them.

## Instructions
Add something like this to your mpv config:
```
vo=gpu-next
glsl-shader="path/to/shader/CfL_Prediction.glsl"
```
`gpu-next` is currently required for the shader to be able to do linear downscaling, but if you want to use it on `gpu` you can safely just remove the `linearize()` and `delinearize()` functions.