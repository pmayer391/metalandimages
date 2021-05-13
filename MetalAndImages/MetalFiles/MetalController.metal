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
                   device uint *flaggedArray [[buffer(2)]],
                   uint2 id [[thread_position_in_grid]]) {
    
    float3 val = inTexture.read(id).rgb;

    float gray = (val.r + val.g + val.b)/3.0;
    float4 out = float4(gray, gray, gray, 1.0);
    outTexture.write(out.rgba, id);
    
//    float4 white = float4(255.0, 255.0, 255.0, 1);
//    float4 black = float4(0, 0, 0, 1);
//
//
//    uint rowIndex = id.x;
//    uint columnIndex = id.y;
//    //Is Black
//
//    if (val[0] >= 1 || val[1] >= 1 || val[2] >= 1){
//        outTexture.write(black, id);
//        flaggedArray[id.x] = 1;
////        flaggedArray[columnIndex][rowIndex] = 1;
//    } else { // Is White
//        outTexture.write(white, id);
//        flaggedArray[id.x] = 2;
////        flaggedArray[columnIndex][rowIndex] = 1;
//    }
//
//    if (id.y == 0){
////        flaggedArray[id.x] = 1;
////        flaggedArray[id.x] = 1;
//    } else{
////        flaggedArray[id.x * id.y] = 1;
//    }
//    flaggedArray[id.x] = 1;
    
}
