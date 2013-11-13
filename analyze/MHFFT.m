//
//  MHFFT.m
//  analyze
//
//  Created by Mike Hays on 11/12/13.
//  Copyright (c) 2013 Mike Hays. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import "MHFFT.h"

@implementation MHFFT {
    UInt32 _length;
    FFTSetup _setup;
    vDSP_Length _log2Length;
    Float32 *_window;

    DSPSplitComplex _deinterleavedSamples;

    Float32 *_samples;
    DSPSplitComplex _splitSamples;
    Float32 *_magnitude;
}

- (id)initWithLength:(UInt32)length // input length
{
    self = [super init];
    if (self) {
        _length = length;
        _log2Length = log2f(_length);
        _setup = vDSP_create_fftsetup(_log2Length, FFT_RADIX2);

        _window = (Float32 *) malloc(sizeof(float) * _length);
        memset(_window, 0, sizeof(float) * _length);
//        vDSP_hann_window(_window, _length, vDSP_HANN_DENORM);    //
        vDSP_hamm_window(_window, _length, 0);

        //    Float32 scale = 1.0f / (float)(4.0f * _size);

        _deinterleavedSamples.realp = malloc(_length * sizeof(Float32));
        _deinterleavedSamples.imagp = malloc(_length * sizeof(Float32));

        _samples = malloc(_length * sizeof(Float32));

        _splitSamples.realp = malloc(_length * sizeof(Float32));
        _splitSamples.imagp = malloc(_length * sizeof(Float32));

        _magnitude = malloc(_length * sizeof(Float32));
    }
    return self;
}

- (void)dealloc
{
    vDSP_destroy_fftsetup(_setup);
    free(_window);
    free(_deinterleavedSamples.realp);
    free(_deinterleavedSamples.imagp);
    free(_samples);
    free(_splitSamples.realp);
    free(_splitSamples.imagp);
    free(_magnitude);
}

- (Float32 *)forward:(Float32 *)interleavedSamples
{
    vDSP_ctoz((DSPComplex *)interleavedSamples, 2, &_deinterleavedSamples, 1, _length);
    vDSP_vmul(_deinterleavedSamples.realp, 1, _window, 1, _samples, 1, _length);
    vDSP_ctoz((DSPComplex *)_samples, 2, &_splitSamples, 1, _length / 2);
//    vDSP_vmul(_deinterleavedSamples.imagp, 1, _window, 1, _rightSplitSamples.realp, 1, _length);
    vDSP_fft_zrip(_setup, &_splitSamples, 1, _log2Length, FFT_FORWARD);

    _splitSamples.imagp[0] = 0.0;   // wtf? does this have something to do with packing?

    vDSP_vdist(_splitSamples.realp, 1, _splitSamples.imagp, 1, _magnitude, 1, _length / 2);
    return _magnitude;   // phase?
}

@end
