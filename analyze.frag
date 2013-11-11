#version 120

void main(void)
{
    gl_FragColor = vec4(gl_FragCoord.xy / 320.0, 0.0, 0.0);
}
