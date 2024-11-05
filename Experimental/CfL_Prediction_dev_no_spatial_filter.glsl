// MIT License

// Copyright (c) 2023 João Chrisóstomo

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

//!PARAM chroma_offset_x
//!TYPE float
0.0

//!PARAM chroma_offset_y
//!TYPE float
0.0

//!HOOK CHROMA
//!BIND LUMA
//!BIND CHROMA
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT CHROMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Downscaling Luma)

vec4 hook() {
    return LUMA_texOff(vec2(chroma_offset_x, chroma_offset_y));
}

//!HOOK NATIVE
//!BIND NATIVE
//!BIND CHROMA
//!BIND LUMA_LOWRES
//!DESC Chroma From Luma Prediction (Local Linear Regression)

#define DEBUG 0

vec4 hook() {
    float mix_coeff = 0.8;
    vec2 corr_exponent = vec2(4.0);

    vec4 output_pix = NATIVE_texOff(0);
    float luma_zero = output_pix.x;
    vec2 chroma_zero = output_pix.yz;

    vec2 pp = CHROMA_pos * CHROMA_size - vec2(0.5);
    vec2 fp = floor(pp);

#ifdef CHROMA_gather
    vec2 quad_idx[4] = {{0.0, 0.0}, {2.0, 0.0}, {0.0, 2.0}, {2.0, 2.0}};

    vec4 luma_quads[4];
    vec4 chroma_quads[4][2];

    for (int i = 0; i < 4; i++) {
        luma_quads[i] = LUMA_LOWRES_gather(vec2((fp + quad_idx[i]) * CHROMA_pt), 0);
        chroma_quads[i][0] = CHROMA_gather(vec2((fp + quad_idx[i]) * CHROMA_pt), 0);
        chroma_quads[i][1] = CHROMA_gather(vec2((fp + quad_idx[i]) * CHROMA_pt), 1);
    }

    vec2 chroma_pixels[12];
    chroma_pixels[0]  = vec2(chroma_quads[0][0].z, chroma_quads[0][1].z);
    chroma_pixels[1]  = vec2(chroma_quads[1][0].w, chroma_quads[1][1].w);
    chroma_pixels[2]  = vec2(chroma_quads[0][0].x, chroma_quads[0][1].x);
    chroma_pixels[3]  = vec2(chroma_quads[0][0].y, chroma_quads[0][1].y);
    chroma_pixels[4]  = vec2(chroma_quads[1][0].x, chroma_quads[1][1].x);
    chroma_pixels[5]  = vec2(chroma_quads[1][0].y, chroma_quads[1][1].y);
    chroma_pixels[6]  = vec2(chroma_quads[2][0].w, chroma_quads[2][1].w);
    chroma_pixels[7]  = vec2(chroma_quads[2][0].z, chroma_quads[2][1].z);
    chroma_pixels[8]  = vec2(chroma_quads[3][0].w, chroma_quads[3][1].w);
    chroma_pixels[9]  = vec2(chroma_quads[3][0].z, chroma_quads[3][1].z);
    chroma_pixels[10] = vec2(chroma_quads[2][0].y, chroma_quads[2][1].y);
    chroma_pixels[11] = vec2(chroma_quads[3][0].x, chroma_quads[3][1].x);

    float luma_pixels[12];
    luma_pixels[0]  = luma_quads[0].z;
    luma_pixels[1]  = luma_quads[1].w;
    luma_pixels[2]  = luma_quads[0].x;
    luma_pixels[3]  = luma_quads[0].y;
    luma_pixels[4]  = luma_quads[1].x;
    luma_pixels[5]  = luma_quads[1].y;
    luma_pixels[6]  = luma_quads[2].w;
    luma_pixels[7]  = luma_quads[2].z;
    luma_pixels[8]  = luma_quads[3].w;
    luma_pixels[9]  = luma_quads[3].z;
    luma_pixels[10] = luma_quads[2].y;
    luma_pixels[11] = luma_quads[3].x;
#else
    vec2 pix_idx[12] = {             {0.5,-0.5}, {1.5,-0.5},
                        {-0.5, 0.5}, {0.5, 0.5}, {1.5, 0.5}, {2.5, 0.5},
                        {-0.5, 1.5}, {0.5, 1.5}, {1.5, 1.5}, {2.5, 1.5},
                                     {0.5, 2.5}, {1.5, 2.5}            };

    float luma_pixels[12];
    vec2 chroma_pixels[12];

    for (int i = 0; i < 12; i++) {
        luma_pixels[i] = LUMA_LOWRES_tex(vec2((fp + pix_idx[i]) * CHROMA_pt)).x;
        chroma_pixels[i] = CHROMA_tex(vec2((fp + pix_idx[i]) * CHROMA_pt)).xy;
    }
#endif

#if (DEBUG == 1)
    mix_coeff = 1.0;
    chroma_zero = vec2(0.5);
#endif

    float luma_avg = 0.0;
    float luma_var = 0.0;
    vec2 chroma_avg = vec2(0.0);
    vec2 chroma_var = vec2(0.0);
    vec2 luma_chroma_cov = vec2(0.0);

    for (int i = 0; i < 12; i++) {
        luma_avg += luma_pixels[i];
        chroma_avg += chroma_pixels[i];
    }

    luma_avg /= 12.0;
    chroma_avg /= 12.0;

    for (int i = 0; i < 12; i++) {
        luma_var += pow(luma_pixels[i] - luma_avg, 2.0);
        chroma_var += pow(chroma_pixels[i] - chroma_avg, vec2(2.0));
        luma_chroma_cov += (luma_pixels[i] - luma_avg) * (chroma_pixels[i] - chroma_avg);
    }

    vec2 corr = clamp(abs(luma_chroma_cov / max(sqrt(luma_var * chroma_var), 1e-6)), 0.0, 1.0);

    vec2 alpha = luma_chroma_cov / max(luma_var, 1e-6);
    vec2 beta = chroma_avg - alpha * luma_avg;
    vec2 chroma_pred = clamp(alpha * luma_zero + beta, 0.0, 1.0);

    output_pix.yz = mix(chroma_zero, chroma_pred, pow(corr, corr_exponent) * mix_coeff);
    output_pix.yz = clamp(output_pix.yz, 0.0, 1.0);
    return output_pix;
}

//!PARAM distance_coeff
//!TYPE float
//!MINIMUM 0.0
2.0

//!PARAM intensity_coeff
//!TYPE float
//!MINIMUM 0.0
128.0

//!HOOK NATIVE
//!BIND NATIVE
//!DESC Chroma From Luma Prediction (Smoothing Chroma)

float comp_w(vec2 spatial_distance, float intensity_distance) {
    return max(100.0 * exp(-distance_coeff * pow(length(spatial_distance), 2.0) - intensity_coeff * pow(intensity_distance, 2.0)), 1e-32);
}

vec4 hook() {
    vec4 output_pix = NATIVE_texOff(0);
    float wt = 0.0;
    vec2 ct = vec2(0.0);

    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            vec4 native_pixels = NATIVE_texOff(vec2(i, j));
            float w = comp_w(vec2(i, j), output_pix.x - native_pixels.x);
            wt += w;
            ct += w * native_pixels.yz;
        }
    }

    output_pix.yz = clamp(ct / wt, 0.0, 1.0);
    return output_pix;
}
