/***********************************************************************************************************************
*                                                                                                                      *
* libscopehal                                                                                                          *
*                                                                                                                      *
* Copyright (c) 2012-2025 Andrew D. Zonenberg and contributors                                                         *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/

/**
	@file
	@brief Partial calculation of the RMS of an AC signal with the DC component removed
 */

#version 430
#pragma shader_stage(compute)

layout(std430, binding=0) restrict writeonly buffer buf_pout
{
	float pout[];
};

layout(std430, binding=1) restrict readonly buffer buf_pin
{
	float pin[];
};

layout(std430, push_constant) uniform constants
{
	uint numSamples;
	uint numThreads;
	uint samplesPerThread;
	float dcBias;
};

layout(local_size_x=64, local_size_y=1, local_size_z=1) in;

void main()
{
	uint nthread = (gl_GlobalInvocationID.y * gl_NumWorkGroups.x * gl_WorkGroupSize.x) + gl_GlobalInvocationID.x;
	if(nthread >= numThreads)
		return;

	//Find region to average
	uint nstart = nthread * samplesPerThread;
	uint nend = nstart + samplesPerThread;
	if(nend > numSamples)
		nend = numSamples;

	//Kahan summation to improve numerical stability
	float temp = 0;
	float c = 0;
	for(uint i=nstart; i<nend; i++)
	{
		float delta = pin[i] - dcBias;
		float deltaSquared = delta * delta;
		float y = deltaSquared - c;
		float t = temp + y;
		c = (t - temp) - y;
		temp = t;
	}

	pout[nthread] = temp;
}

