# GLSL Chroma from Luma (CfL) Prediction
The shaders implement the closed least squares solution for linear regression. This is extremely unstable on homogeneous surfaces, and the prediction can also easily be out of bonds which makes clipping needed. 
Since a simple linear regression obviously doesn't take into account pixel distance, the prediction is mixed with the output of a normal resampling filter based on how high the correlation between luma and chroma is.

This is technically a work in progress but I genuinely don't think there's any point in trying to polish it further. While it can kinda produce good numbers, it's still generally worse than just kriging the missing values 
when there's a lot of high-frequency information involved. On real video content however, the shaders seem good enough and the 4-tap variant can routinely score higher than KrigBilateral.

The idea makes sense and [it has been employed in video codecs](https://arxiv.org/abs/1711.03951), however, codecs still encode the missing information *on top* of the prediction so it isn't exactly the same. In their case, this is just another technique to save some bitrate.

The shaders are more or less self-explanatory but the 4-tap variant is the "sharpest" and "most accurate" one, albeit also the most unstable one. The "mix" variant is just a hack that combines the 4-tap and the 12-tap variants in an attempt to reduce the amount of visible artifacts, since the artifacts get blended together.

The 16-tap variant doesn't really have any benefits other than being generally smoother, but it's also prone to picking the wrong colour at sharp chromatic transitions.

In any case, as it stands this is how these shaders perform:

## Benchmarks
| Shader/Filter  | MAE    | PSNR    | SSIM   | MS-SSIM |   | MAE (N) | PSNR (N) | SSIM (N) | MS-SSIM (N) |   | Mean   |
|----------------|--------|---------|--------|---------|---|---------|----------|----------|-------------|---|--------|
| cflmix         | 0.0028 | 44.1411 | 0.9939 |  0.9987 |   |  0.9526 |   0.9920 |   1.0000 |      0.9634 |   | 0.9770 |
| krigbilateral  | 0.0028 | 44.1645 | 0.9936 |  0.9988 |   |  0.9147 |   1.0000 |   0.9004 |      1.0000 |   | 0.9538 |
| cfl4           | 0.0028 | 43.5243 | 0.9934 |  0.9987 |   |  1.0000 |   0.7806 |   0.8529 |      0.9041 |   | 0.8844 |
| cfl12          | 0.0030 | 43.7869 | 0.9935 |  0.9986 |   |  0.7750 |   0.8706 |   0.8573 |      0.8368 |   | 0.8349 |
| cfl16          | 0.0032 | 43.2266 | 0.9927 |  0.9983 |   |  0.5281 |   0.6786 |   0.6234 |      0.6358 |   | 0.6165 |
| jointbilateral | 0.0032 | 42.6758 | 0.9917 |  0.9985 |   |  0.4722 |   0.4899 |   0.3501 |      0.7797 |   | 0.5230 |
| fastbilateral  | 0.0032 | 42.5421 | 0.9917 |  0.9985 |   |  0.4843 |   0.4441 |   0.3468 |      0.7477 |   | 0.5057 |
| lanczos        | 0.0034 | 42.0579 | 0.9918 |  0.9975 |   |  0.2756 |   0.2782 |   0.3664 |      0.0549 |   | 0.2438 |
| polar_lanczos  | 0.0034 | 42.0058 | 0.9917 |  0.9975 |   |  0.2525 |   0.2603 |   0.3455 |      0.0384 |   | 0.2242 |
| bilinear       | 0.0037 | 41.2460 | 0.9906 |  0.9975 |   |  0.0000 |   0.0000 |   0.0000 |      0.0000 |   | 0.0000 |

Just keep in mind that these numbers may not always be up to date.