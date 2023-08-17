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
| cfl_4tap       | 0.0015 | 48.5037 | 0.9968 |  0.9996 |   |  1.0000 |   1.0000 |   1.0000 |      1.0000 |   | 1.0000 |
| cfl_mix        | 0.0017 | 48.1647 | 0.9966 |  0.9995 |   |  0.7061 |   0.8500 |   0.8112 |      0.7823 |   | 0.7874 |
| krigbilateral  | 0.0016 | 48.0584 | 0.9965 |  0.9996 |   |  0.7693 |   0.8030 |   0.6716 |      0.8727 |   | 0.7792 |
| cfl_12tap      | 0.0018 | 47.4755 | 0.9963 |  0.9995 |   |  0.4527 |   0.5452 |   0.4381 |      0.5351 |   | 0.4928 |
| lanczos        | 0.0018 | 47.1755 | 0.9965 |  0.9994 |   |  0.3855 |   0.4125 |   0.6601 |      0.2760 |   | 0.4335 |
| polar_lanczos  | 0.0018 | 47.0847 | 0.9964 |  0.9994 |   |  0.3304 |   0.3724 |   0.6088 |      0.2114 |   | 0.3808 |
| fastbilateral  | 0.0018 | 46.7015 | 0.9960 |  0.9994 |   |  0.2582 |   0.2029 |   0.2112 |      0.4364 |   | 0.2772 |
| cfl_16tap      | 0.0019 | 46.9027 | 0.9959 |  0.9994 |   |  0.1161 |   0.2919 |   0.0829 |      0.2254 |   | 0.1791 |
| jointbilateral | 0.0019 | 46.5899 | 0.9958 |  0.9994 |   |  0.1089 |   0.1535 |   0.0000 |      0.3971 |   | 0.1649 |
| bilinear       | 0.0020 | 46.2429 | 0.9958 |  0.9993 |   |  0.0000 |   0.0000 |   0.0083 |      0.0000 |   | 0.0021 |

Just keep in mind that these numbers may not always be up to date.