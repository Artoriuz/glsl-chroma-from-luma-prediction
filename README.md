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
| Shader/Filter  | MAE      | PSNR    | SSIM   | MS-SSIM |   | MAE (N) | PSNR (N) | SSIM (N) | MS-SSIM (N) |   | Mean   |
|----------------|----------|---------|--------|---------|---|---------|----------|----------|-------------|---|--------|
| cfl_4tap       | 9.41E-04 | 51.0104 | 0.9980 |  0.9996 |   |  1.0000 |   1.0000 |   1.0000 |      1.0000 |   | 1.0000 |
| cfl_mix        | 1.02E-03 | 50.8475 | 0.9979 |  0.9995 |   |  0.8443 |   0.9463 |   0.9026 |      0.9322 |   | 0.9063 |
| krigbilateral  | 1.03E-03 | 51.0087 | 0.9977 |  0.9996 |   |  0.8082 |   0.9994 |   0.7875 |      0.9910 |   | 0.8965 |
| cfl_12tap      | 1.06E-03 | 50.3955 | 0.9977 |  0.9995 |   |  0.7583 |   0.7974 |   0.7695 |      0.8469 |   | 0.7930 |
| cfl_16tap      | 1.12E-03 | 49.9846 | 0.9975 |  0.9995 |   |  0.6340 |   0.6621 |   0.6276 |      0.7333 |   | 0.6642 |
| fastbilateral  | 1.26E-03 | 49.2835 | 0.9972 |  0.9994 |   |  0.3308 |   0.4311 |   0.3426 |      0.5503 |   | 0.4137 |
| jointbilateral | 1.29E-03 | 49.1986 | 0.9971 |  0.9994 |   |  0.2563 |   0.4032 |   0.2450 |      0.5030 |   | 0.3519 |
| polar_lanczos  | 1.31E-03 | 48.6640 | 0.9971 |  0.9991 |   |  0.2173 |   0.2270 |   0.2970 |      0.0000 |   | 0.1853 |
| lanczos        | 1.34E-03 | 48.6891 | 0.9971 |  0.9992 |   |  0.1646 |   0.2353 |   0.2640 |      0.0062 |   | 0.1675 |
| bilinear       | 1.42E-03 | 47.9748 | 0.9968 |  0.9992 |   |  0.0000 |   0.0000 |   0.0000 |      0.0024 |   | 0.0006 |

Just keep in mind that these numbers may not always be up to date.