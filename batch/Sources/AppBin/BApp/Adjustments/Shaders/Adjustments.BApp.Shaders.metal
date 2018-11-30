//
//  Adjustments.BApp.Shaders.metal
//  pap
//
//  Created by HYOJIN MO on 29/11/2018.
//  Copyright © 2018 Stells. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {
        float4 fade(sample_t s, float intensity) {
            // https://computergraphics.stackexchange.com/questions/1833/instagrams-fade-effect
            // x′=0.77x+38
            return float4(s.rgb * (0.77 + 0.23 * (1.0 - intensity)) + (0.15 * intensity), 1);
        }
    }
}
