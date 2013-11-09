//
//  Shader.fsh
//  Circuitry
//
//  Created by Anthony Foster on 9/11/2013.
//  Copyright (c) 2013 Circuitry. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
