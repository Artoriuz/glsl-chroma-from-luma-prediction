# GLSL Chroma from Luma (CfL) Prediction
The shaders implement the closed least squares solution for linear regression. This is extremely unstable on homogeneous surfaces, and the prediction can also easily be out of bonds which makes clipping needed. 
Since a simple linear regression obviously doesn't take into account pixel distance, the prediction is mixed with the output of a normal resampling filter based on how high the correlation between luma and chroma is.

This is technically a work in progress but I genuinely don't think there's any point in trying to polish it further. While it can kinda produce good numbers, it's still generally worse than just kriging the missing values 
when there's a lot of high-frequency information involved. On real video content however, the shaders seem good enough and the 4-tap variant can routinely score higher than KrigBilateral.

The idea makes sense and [it has been employed in video codecs](https://arxiv.org/abs/1711.03951), however, codecs still encode the missing information *on top* of the prediction so it isn't exactly the same. In their case, this is just another technique to save some bitrate.

The shaders are more or less self-explanatory but the 4-tap variant is the "sharpest" and "most accurate" one, albeit also the most unstable one. The "mix" variant is just a hack that combines the 4-tap and the 12-tap variants in an attempt to reduce the amount of visible artifacts, since the artifacts get blended together.

The 16-tap variant doesn't really have any benefits other than being generally smoother, but it's also prone to picking the wrong colour at sharp chromatic transitions.

In any case, as it stands this is how these shaders perform:

| Shader/Filter  | MAE    | PSNR    | SSIM   | MS-SSIM |   | MAE (N) | PSNR (N) | SSIM (N) | MS-SSIM (N) |   | Mean   |
|----------------|--------|---------|--------|---------|---|---------|----------|----------|-------------|---|--------|
| cfl4           | 0.0025 | 41.0440 | 0.9943 |  0.9994 |   |  1.0000 |   0.9730 |   1.0000 |      1.0000 |   | 0.9932 |
| krigbilateral  | 0.0025 | 41.1124 | 0.9941 |  0.9994 |   |  0.9224 |   1.0000 |   0.9473 |      0.9984 |   | 0.9670 |
| cfl_mix        | 0.0026 | 41.0592 | 0.9942 |  0.9993 |   |  0.8986 |   0.9790 |   0.9734 |      0.9617 |   | 0.9532 |
| cfl12          | 0.0027 | 40.6884 | 0.9938 |  0.9993 |   |  0.7529 |   0.8324 |   0.8635 |      0.8799 |   | 0.8322 |
| cfl16          | 0.0028 | 40.4799 | 0.9934 |  0.9992 |   |  0.6330 |   0.7500 |   0.7834 |      0.7986 |   | 0.7413 |
| jointbilateral | 0.0027 | 40.2050 | 0.9928 |  0.9992 |   |  0.6779 |   0.6413 |   0.6120 |      0.7938 |   | 0.6813 |
| fastbilateral  | 0.0027 | 40.1569 | 0.9928 |  0.9991 |   |  0.6937 |   0.6223 |   0.6114 |      0.7089 |   | 0.6591 |
| sinc2ar        | 0.0030 | 39.5121 | 0.9919 |  0.9987 |   |  0.3958 |   0.3674 |   0.3757 |      0.0886 |   | 0.3069 |
| lanczos        | 0.0031 | 39.3481 | 0.9915 |  0.9987 |   |  0.2417 |   0.3026 |   0.2617 |      0.1711 |   | 0.2443 |
| polar_lanczos  | 0.0032 | 39.1656 | 0.9911 |  0.9987 |   |  0.1228 |   0.2305 |   0.1625 |      0.0654 |   | 0.1453 |
| bilinear       | 0.0033 | 38.5826 | 0.9905 |  0.9986 |   |  0.0000 |   0.0000 |   0.0000 |      0.0000 |   | 0.0000 |

Just keep in mind that these numbers may not always be up to date.