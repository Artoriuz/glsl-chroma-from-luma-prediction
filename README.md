# GLSL Chroma from Luma (CfL) Prediction
The shaders implement chroma upscaling based on the closed least squares solution for linear regression, [inspired by the adoption of the same technique in modern video codecs](https://arxiv.org/abs/1711.03951).
Since a simple linear regression obviously doesn't take into account pixel distance, the prediction is mixed with the output of a normal resampling filter based on how high the correlation between luma and chroma is.

The shaders are experimental and minor improvements are being made over time. If you have any suggestions, feel free to send them as well.
