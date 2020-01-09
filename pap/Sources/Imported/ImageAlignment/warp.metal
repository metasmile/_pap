//
//  filters.metal
//  pixelstabilizer
//
//  Created by Hyojin Mo on 2017. 11. 9..
//  Copyright © 2017년 Codeful. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

typedef struct {
    float2 translation;
    float3x3 matrix;
    float2 size;
    float2 clampRange;
} WarpMatrix;

vertex SingleInputVertexIO warpHomographic(const device packed_float2 *position [[buffer(0)]],
                                           const device packed_float2 *texturecoord [[buffer(1)]],
                                           constant WarpMatrix &warpMatrix [[buffer(2)]],
                                           uint vid [[vertex_id]])
{
    SingleInputVertexIO outputVertices;
    
    float2 destCoord = position[vid] * warpMatrix.size;
    float3 homogeneousDestCoord = float3(destCoord, 1.0);
    float3 homogeneousSrcCoord = warpMatrix.matrix * homogeneousDestCoord;
    float2 srcCoord = homogeneousSrcCoord.xy / max(homogeneousSrcCoord.z, 0.000001);
    float2 translation = clamp(destCoord - srcCoord, -warpMatrix.clampRange, warpMatrix.clampRange);
    
    outputVertices.position = float4((destCoord + translation) / warpMatrix.size, 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];
    
    return outputVertices;
}

vertex SingleInputVertexIO warpTranslation(const device packed_float2 *position [[buffer(0)]],
                                           const device packed_float2 *texturecoord [[buffer(1)]],
                                           constant WarpMatrix &warpMatrix [[buffer(2)]],
                                           uint vid [[vertex_id]])
{
    SingleInputVertexIO outputVertices;
    
    float2 destCoord = position[vid];
    
    outputVertices.position = float4(destCoord + clamp(warpMatrix.translation, -warpMatrix.clampRange, warpMatrix.clampRange), 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];
    
    return outputVertices;
}
