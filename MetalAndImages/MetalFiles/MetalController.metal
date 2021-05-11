//
//  MetalController.metal
//  MetalAndImages
//
//  Created by Paul Mayer on 5/10/21.
//

#include <metal_stdlib>
using namespace metal;


kernel void black (texture2d<float, access::write> outTexture [[texture(0)]],
                   texture2d<float, access::read> inTexture [[texture(1)]],
                   uint2 id [[thread_position_in_grid]]) {
    
    float3 val = inTexture.read(id).rgb;
    float gray = (val.r + val.g + val.b)/3.0;
    float4 out = float4(gray, gray, gray, 1.0);
    float4 white = float4(255.0, 255.0,255.0, 1);
    float4 black = float4(0, 0, 0, 1);
    
    outTexture.write(out.rgba, id);
//    outTexture.write(black, id);
//    outTexture.write(rgbFloat, id);
}
