//!HOOK LUMA
//!BIND HOOKED
//!WIDTH HOOKED.w 2.0 /
//!HEIGHT HOOKED.h 2.0 /
//!WHEN HOOKED.w 2 % ! HOOKED.h 2 % ! *

vec4 hook() {
    return HOOKED_texOff(0);
}
