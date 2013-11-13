#version 150

out vec4 fragColor;

void main(void)
{
    fragColor = vec4(gl_FragCoord.y / 320.0, 1 - gl_FragCoord.y / 240.0, 0.0, 0.0);
}
