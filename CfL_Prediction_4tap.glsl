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
//!BIND LUMA
//!BIND HOOKED
//!SAVE LUMA_LOWRES
//!WHEN CHROMA.w LUMA.w <
//!DESC Chroma From Luma Prediction (Downscaling Luma)

vec4 hook() {
    vec2 start  = ceil((LUMA_pos - CHROMA_pt) * LUMA_size - 0.5);
    vec2 end = floor((LUMA_pos + CHROMA_pt) * LUMA_size - 0.5);

    float luma_pix = 0.0;
    float w = 0.0;
    float d = 0.0;
    float wt = 0.0;
    float val = 0.0;
    vec2 pos = LUMA_pos;

    for (float dx = start.x; dx <= end.x; dx++) {
        for (float dy = start.y; dy <= end.y; dy++) {
            pos = LUMA_pt * vec2(dx + 0.5, dy + 0.5);
            d = length((pos - LUMA_pos) * CHROMA_size);
            w = exp(-2.0 * pow(d, 2.0));
            luma_pix = LUMA_tex(pos).x;
            val += w * luma_pix;
            wt += w;
        }
    }

    vec4 output_pix = vec4(val / wt, 0.0, 0.0, 1.0);
    return output_pix;
}

//!HOOK NATIVE
//!BIND NATIVE
//!BIND CHROMA
//!BIND LUMA_LOWRES
//!WHEN CHROMA.w LUMA.w <
//!OFFSET ALIGN
//!DESC Chroma From Luma Prediction (4-tap) (Chroma Upscaling)

vec4 hook() {
    vec4 output_pix = NATIVE_texOff(0.0);
    vec2 pp = CHROMA_pos * CHROMA_size - vec2(0.5);
    vec2 fp = floor(pp);

    vec2 chroma_pixels[4];
    chroma_pixels[0] = CHROMA_tex(vec2(fp + vec2(0.5)) * CHROMA_pt).xy;
    chroma_pixels[1] = CHROMA_tex(vec2(fp + vec2(0.5, 1.5)) * CHROMA_pt).xy;
    chroma_pixels[2] = CHROMA_tex(vec2(fp + vec2(1.5, 0.5)) * CHROMA_pt).xy;
    chroma_pixels[3] = CHROMA_tex(vec2(fp + vec2(1.5, 1.5)) * CHROMA_pt).xy;

    float luma_pixels[4];
    luma_pixels[0] = LUMA_LOWRES_tex(vec2(fp + vec2(0.5)) * CHROMA_pt).x;
    luma_pixels[1] = LUMA_LOWRES_tex(vec2(fp + vec2(0.5, 1.5)) * CHROMA_pt).x;
    luma_pixels[2] = LUMA_LOWRES_tex(vec2(fp + vec2(1.5, 0.5)) * CHROMA_pt).x;
    luma_pixels[3] = LUMA_LOWRES_tex(vec2(fp + vec2(1.5, 1.5)) * CHROMA_pt).x;

    // vec2 chroma_min = vec2(1e8);
    // chroma_min = min(chroma_min, chroma_pixels[0]);
    // chroma_min = min(chroma_min, chroma_pixels[1]);
    // chroma_min = min(chroma_min, chroma_pixels[2]);
    // chroma_min = min(chroma_min, chroma_pixels[3]);
    
    // vec2 chroma_max = vec2(1e-8);
    // chroma_max = max(chroma_max, chroma_pixels[0]);
    // chroma_max = max(chroma_max, chroma_pixels[1]);
    // chroma_max = max(chroma_max, chroma_pixels[2]);
    // chroma_max = max(chroma_max, chroma_pixels[3]);

    float luma_avg = 0.0;
    for(int i = 0; i < 4; i++) {
        luma_avg += luma_pixels[i];
    }
    luma_avg /= 4.0;
    
    float luma_var = 0.0;
    for(int i = 0; i < 4; i++) {
        luma_var += pow(luma_pixels[i] - luma_avg, 2.0);
    }
    
    vec2 chroma_avg = vec2(0.0);
    for(int i = 0; i < 4; i++) {
        chroma_avg += chroma_pixels[i];
    }
    chroma_avg /= 4.0;
    
    vec2 chroma_var = vec2(0.0);
    for(int i = 0; i < 4; i++) {
        chroma_var += pow(chroma_pixels[i] - chroma_avg, vec2(2.0));
    }
    
    vec2 luma_chroma_cov = vec2(0.0);
    for(int i = 0; i < 4; i++) {
        luma_chroma_cov += (luma_pixels[i] - luma_avg) * (chroma_pixels[i] - chroma_avg);
    }
    
    vec2 corr = abs(luma_chroma_cov / max(sqrt(luma_var * chroma_var), 1e-6));
    corr = clamp(corr, 0.0, 1.0);

    vec2 alpha = luma_chroma_cov / max(luma_var, 1e-6);
    vec2 beta = chroma_avg - alpha * luma_avg;

    vec2 chroma_pred = alpha * output_pix.x + beta;
    chroma_pred = clamp(chroma_pred, 0.0, 1.0);

    output_pix.yz = mix(output_pix.yz, chroma_pred, 0.25);

    // Replace this with chroma_min and chroma_max if you want AR
    output_pix.yz = clamp(output_pix.yz, 0.0, 1.0);
    return  output_pix;
}