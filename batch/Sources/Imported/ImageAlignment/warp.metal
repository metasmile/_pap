//
//  filters.metal
//  pixelstabilizer
//
//  Created by Hyojin Mo on 2017. 11. 9..
//  Copyright © 2017년 Codeful. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>

struct destination {
    float2 coord() const;
};

struct sampler {
    float2 transform(float2 p) const;
    float2 coord() const;
    float4 sample(float2 p) const;
    float4 extent() const;
};

extern "C" { namespace coreimage {
    float2 warpHomography(float3x3 h, destination dest) {
        float3 homogeneousDestCoord = float3(dest.coord(), 1.0);
        float3 homogeneousSrcCoord = h * homogeneousDestCoord;
        float2 srcCoord = homogeneousSrcCoord.xy / max(homogeneousSrcCoord.z, 0.000001);
        return srcCoord;
    }
    
    float2 translate(float2 t, destination dest) {
        return dest.coord() + t;
    }
}}
