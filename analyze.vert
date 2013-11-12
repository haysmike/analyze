#version 150

in vec4 sample;

void main(void)
{
//    gl_Position = vec4((gl_VertexID / 1024.0 - 1.0) * 0.95, (sample.x / 2.0 - 1.0) * 0.95, 0.0, 1.0);
    gl_Position = vec4(0.95 * (log(gl_VertexID + 1.0)/log(2)/5.5 - 1.0),
                       0.95 * (log(gl_VertexID + 2.0)/10.0 * log(sample.x + 1.0) - 1),
                       0.0,
                       1.0);
}
