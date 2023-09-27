# GLSL Chroma from Luma (CfL) Prediction
The shaders implement the closed least squares solution for linear regression. This is extremely unstable on homogeneous surfaces, and the prediction can also easily be out of bounds which makes clipping needed. 
Since a simple linear regression obviously doesn't take into account pixel distance, the prediction is mixed with the output of a normal resampling filter based on how high the correlation between luma and chroma is.

This is technically a work in progress but I genuinely don't think there's any point in trying to polish it further. While it can kinda produce good numbers, it's still generally worse than just kriging the missing values when there's a lot of high-frequency information involved.

The idea makes sense and [it has been employed in video codecs](https://arxiv.org/abs/1711.03951), however, codecs still encode the missing information *on top* of the prediction so it isn't exactly the same. In their case, this is just another technique to save some bitrate.

The shaders are more or less self-explanatory but the 4-tap variant is the "sharpest" and "most accurate" one, albeit also the most unstable one. The "mix" variant is just a hack that combines the 4-tap and the 12-tap variants in an attempt to reduce the amount of visible artifacts, since the artifacts get blended together.

The 16-tap variant doesn't really have any benefits other than being generally smoother, but it's also prone to picking the wrong colour at sharp chromatic transitions.
