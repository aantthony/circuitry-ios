//
//  Shader.fsh
//  Circuity
//
//  Created by Anthony Foster on 30/10/2013.
//  Copyright (c) 2013 Anthony Foster. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
