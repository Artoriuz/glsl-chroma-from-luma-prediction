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

//!HOOK CHROMA
//!BIND CHROMA
//!BIND LUMA
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT LUMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Downscaling Luma 1st Step)

vec4 hook() {
    float factor = ceil(LUMA_size.x / CHROMA_size.x);
    int start = int(ceil(-factor - 0.5));
    int end = int(floor(factor - 0.5));
    float filter_end = float(end) + 1.5;

    float output_luma = 0.0;
    float wt = 0.0;
    for (int dx = start; dx <= end; dx++) {
        float luma_pix = LUMA_texOff(vec2(dx + 0.5, 0.0)).x;
        float wd = smoothstep(0.0, filter_end, filter_end - length(vec2(dx + 0.5, 0.0)));
        output_luma += luma_pix * wd;
        wt += wd;
    }
    vec4 output_pix = vec4(output_luma / wt, 0.0, 0.0, 1.0);
    return output_pix;
}

//!HOOK CHROMA
//!BIND CHROMA
//!BIND LUMA_LOWRES
//!SAVE LUMA_LOWRES
//!WIDTH CHROMA.w
//!HEIGHT CHROMA.h
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Downscaling Luma 2nd Step)

vec4 hook() {
    float factor = ceil(LUMA_LOWRES_size.y / CHROMA_size.y);
    int start = int(ceil(-factor - 0.5));
    int end = int(floor(factor - 0.5));
    float filter_end = float(end) + 1.5;

    float output_luma = 0.0;
    float wt = 0.0;
    for (int dy = start; dy <= end; dy++) {
        float luma_pix = LUMA_LOWRES_texOff(vec2(0.0, dy + 0.5)).x;
        float wd = smoothstep(0.0, filter_end, filter_end - length(vec2(0.0, dy + 0.5)));
        output_luma += luma_pix * wd;
        wt += wd;
    }
    vec4 output_pix = vec4(output_luma / wt, 0.0, 0.0, 1.0);
    return output_pix;
}

//!HOOK NATIVE
//!BIND LUMA_LOWRES
//!BIND CHROMA
//!BIND NATIVE
//!OFFSET ALIGN
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Upscaling Chroma)

vec4 hook() {
    float division_limit = 1e-4;

    vec4 output_pix = NATIVE_texOff(0.0);
    float luma_zero = output_pix.x;

    vec2 pp = CHROMA_pos * CHROMA_size - vec2(0.5);
    vec2 fp = floor(pp);
    pp -= fp;

    vec2 chroma_pixels[12];
    chroma_pixels[0]  = CHROMA_tex(vec2((fp + vec2(0.5, -0.5)) * CHROMA_pt)).xy;
    chroma_pixels[1]  = CHROMA_tex(vec2((fp + vec2(1.5, -0.5)) * CHROMA_pt)).xy;
    chroma_pixels[2]  = CHROMA_tex(vec2((fp + vec2(-0.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[3]  = CHROMA_tex(vec2((fp + vec2( 0.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[4]  = CHROMA_tex(vec2((fp + vec2( 1.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[5]  = CHROMA_tex(vec2((fp + vec2( 2.5, 0.5)) * CHROMA_pt)).xy;
    chroma_pixels[6]  = CHROMA_tex(vec2((fp + vec2(-0.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[7]  = CHROMA_tex(vec2((fp + vec2( 0.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[8]  = CHROMA_tex(vec2((fp + vec2( 1.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[9]  = CHROMA_tex(vec2((fp + vec2( 2.5, 1.5)) * CHROMA_pt)).xy;
    chroma_pixels[10] = CHROMA_tex(vec2((fp + vec2(0.5, 2.5) ) * CHROMA_pt)).xy;
    chroma_pixels[11] = CHROMA_tex(vec2((fp + vec2(1.5, 2.5) ) * CHROMA_pt)).xy;

    float luma_pixels[12];
    luma_pixels[0]  = LUMA_LOWRES_tex(vec2((fp + vec2(0.5, -0.5)) * CHROMA_pt)).x;
    luma_pixels[1]  = LUMA_LOWRES_tex(vec2((fp + vec2(1.5, -0.5)) * CHROMA_pt)).x;
    luma_pixels[2]  = LUMA_LOWRES_tex(vec2((fp + vec2(-0.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[3]  = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[4]  = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[5]  = LUMA_LOWRES_tex(vec2((fp + vec2( 2.5, 0.5)) * CHROMA_pt)).x;
    luma_pixels[6]  = LUMA_LOWRES_tex(vec2((fp + vec2(-0.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[7]  = LUMA_LOWRES_tex(vec2((fp + vec2( 0.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[8]  = LUMA_LOWRES_tex(vec2((fp + vec2( 1.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[9]  = LUMA_LOWRES_tex(vec2((fp + vec2( 2.5, 1.5)) * CHROMA_pt)).x;
    luma_pixels[10] = LUMA_LOWRES_tex(vec2((fp + vec2(0.5, 2.5) ) * CHROMA_pt)).x;
    luma_pixels[11] = LUMA_LOWRES_tex(vec2((fp + vec2(1.5, 2.5) ) * CHROMA_pt)).x;

    float luma_avg_4 = 0.0;
    luma_avg_4 += luma_pixels[3];
    luma_avg_4 += luma_pixels[4];
    luma_avg_4 += luma_pixels[7];
    luma_avg_4 += luma_pixels[8];
    luma_avg_4 /= 4.0;

    float luma_var_4 = 0.0;
    luma_var_4 += pow(luma_pixels[3] - luma_avg_4, 2.0);
    luma_var_4 += pow(luma_pixels[4] - luma_avg_4, 2.0);
    luma_var_4 += pow(luma_pixels[7] - luma_avg_4, 2.0);
    luma_var_4 += pow(luma_pixels[8] - luma_avg_4, 2.0);

    vec2 chroma_avg_4 = vec2(0.0);
    chroma_avg_4 += chroma_pixels[3];
    chroma_avg_4 += chroma_pixels[4];
    chroma_avg_4 += chroma_pixels[7];
    chroma_avg_4 += chroma_pixels[8];
    chroma_avg_4 /= 4.0;

    vec2 luma_chroma_cov_4 = vec2(0.0);
    luma_chroma_cov_4 += (luma_pixels[3] - luma_avg_4) * (chroma_pixels[3] - chroma_avg_4);
    luma_chroma_cov_4 += (luma_pixels[4] - luma_avg_4) * (chroma_pixels[4] - chroma_avg_4);
    luma_chroma_cov_4 += (luma_pixels[7] - luma_avg_4) * (chroma_pixels[7] - chroma_avg_4);
    luma_chroma_cov_4 += (luma_pixels[8] - luma_avg_4) * (chroma_pixels[8] - chroma_avg_4);

    vec2 alpha_4 = luma_chroma_cov_4 / max(luma_var_4, division_limit);
    vec2 beta_4 = chroma_avg_4 - alpha_4 * luma_avg_4;

    vec2 chroma_pred_4 = alpha_4 * luma_zero + beta_4;
    chroma_pred_4 = clamp(chroma_pred_4, 0.0, 1.0);

    float luma_avg_12 = 0.0;
    for(int i = 0; i < 12; i++) {
        luma_avg_12 += luma_pixels[i];
    }
    luma_avg_12 /= 12.0;
    
    float luma_var_12 = 0.0;
    for(int i = 0; i < 12; i++) {
        luma_var_12 += pow(luma_pixels[i] - luma_avg_12, 2.0);
    }
    
    vec2 chroma_avg_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        chroma_avg_12 += chroma_pixels[i];
    }
    chroma_avg_12 /= 12.0;
    
    vec2 chroma_var_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        chroma_var_12 += pow(chroma_pixels[i] - chroma_avg_12, vec2(2.0));
    }
    
    vec2 luma_chroma_cov_12 = vec2(0.0);
    for(int i = 0; i < 12; i++) {
        luma_chroma_cov_12 += (luma_pixels[i] - luma_avg_12) * (chroma_pixels[i] - chroma_avg_12);
    }
    
    vec2 corr = abs(luma_chroma_cov_12 / max(sqrt(luma_var_12 * chroma_var_12), division_limit));
    corr = clamp(corr, 0.0, 1.0);

    vec2 alpha_12 = luma_chroma_cov_12 / max(luma_var_12, division_limit);
    vec2 beta_12 = chroma_avg_12 - alpha_12 * luma_avg_12;

    vec2 chroma_pred_12 = alpha_12 * luma_zero + beta_12;
    chroma_pred_12 = clamp(chroma_pred_12, 0.0, 1.0);

    chroma_pred_4 = mix(output_pix.yz, chroma_pred_4, pow(corr, vec2(2.0)) / 2.0);
    chroma_pred_12 = mix(output_pix.yz, chroma_pred_12, pow(corr, vec2(2.0)) / 2.0);
    output_pix.yz = mix(chroma_pred_4, chroma_pred_12, 0.5);

    output_pix.yz = clamp(output_pix.yz, 0.0, 1.0);
    return  output_pix;
}