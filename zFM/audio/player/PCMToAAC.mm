//
//  PCMToAAC.m
//  zFM
//
//  Created by zykhbl on 16-10-4.
//  Copyright (c) 2016年 zykhbl. All rights reserved.
//

#import "PCMToAAC.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CAXException.h"
#import "CAStreamBasicDescription.h"
#import "rtmp.h"

@interface PCMToAAC ()

@property (nonatomic, assign) AudioConverterRef converter;
@property (nonatomic, assign) UInt32 maxPacketSize;
@property (nonatomic, assign) char *outputBuffer;
@property (nonatomic, assign) AudioStreamPacketDescription *outputPacketDescriptions;

@end

@implementation PCMToAAC

@synthesize converter;
@synthesize maxPacketSize;
@synthesize outputBuffer;
@synthesize outputPacketDescriptions;

- (void)dealloc {    
    if (self.converter) {
        AudioConverterDispose(self.converter);
    }
    
    if (self.outputBuffer) {
        delete [] self.outputBuffer;
    }
    
    if (self.outputPacketDescriptions) {
        delete [] self.outputPacketDescriptions;
    }
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.converter = 0;
        self.maxPacketSize = 0;
        self.outputBuffer = NULL;
        self.outputPacketDescriptions = NULL;
    }
    
    return self;
}

- (void)createConverter {
    try {
        AudioStreamBasicDescription sourceDes, targetDes;
        
        sourceDes.mSampleRate = SAMPLERATE;
        sourceDes.mFormatID = kAudioFormatLinearPCM;
        sourceDes.mChannelsPerFrame = 1;
        sourceDes.mBitsPerChannel = BITSPERCHANNEL;
        sourceDes.mBytesPerPacket = sourceDes.mBytesPerFrame = 2 * sourceDes.mChannelsPerFrame;
        sourceDes.mFramesPerPacket = 1;
        sourceDes.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
        
        memset(&targetDes, 0, sizeof(targetDes));
        targetDes.mSampleRate = SAMPLERATE;
        targetDes.mFormatID = kAudioFormatMPEG4AAC;
        targetDes.mChannelsPerFrame = sourceDes.mChannelsPerFrame;
        UInt32 size = sizeof(targetDes);
        XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &targetDes), "couldnt create target data format");
        
        AudioClassDescription audioClassDes;
        XThrowIfError(AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(targetDes.mFormatID), &targetDes.mFormatID, &size), "cant get kAudioFormatProperty_Encoders");
        UInt32 numEncoders = size/sizeof(AudioClassDescription);
        AudioClassDescription audioClassArr[numEncoders];
        XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(targetDes.mFormatID), &targetDes.mFormatID, &size, audioClassArr), "wrirte audioClassArr fail");
        for (int i = 0; i < numEncoders; i++) {
            if (audioClassArr[i].mSubType == kAudioFormatMPEG4AAC && audioClassArr[i].mManufacturer == kAppleSoftwareAudioCodecManufacturer) {
                memcpy(&audioClassDes, &audioClassArr[i], sizeof(AudioClassDescription));
                break;
            }
        }
        
        XThrowIfError(AudioConverterNewSpecific(&sourceDes, &targetDes, 1, &audioClassDes, &converter), "cant new convertRef");
        
        size = sizeof(sourceDes);
        XThrowIfError(AudioConverterGetProperty(self.converter, kAudioConverterCurrentInputStreamDescription, &size, &sourceDes), "cant get kAudioConverterCurrentInputStreamDescription");
        
        size = sizeof(targetDes);
        XThrowIfError(AudioConverterGetProperty(self.converter, kAudioConverterCurrentOutputStreamDescription, &size, &targetDes), "cant get kAudioConverterCurrentOutputStreamDescription");
        
        UInt32 bitRate = BITRATE;
        size = sizeof(bitRate);
        XThrowIfError(AudioConverterSetProperty(self.converter, kAudioConverterEncodeBitRate, size, &bitRate), "cant set covert property bit rate");
        
        size = sizeof(self.maxPacketSize);
        XThrowIfError(AudioConverterGetProperty(self.converter, kAudioConverterPropertyMaximumOutputPacketSize, &size, &maxPacketSize), "cant get max size of packet");
        self.outputBuffer = new char[self.maxPacketSize];
        
        self.outputPacketDescriptions = new AudioStreamPacketDescription[1];
    } catch (CAXException e) {
		char buf[256];
		NSLog(@"Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
}

OSStatus PCMToAACComplexInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    AudioBufferList *pcmBufferList = (AudioBufferList*)inUserData;
    ioData->mBuffers[0].mData = pcmBufferList->mBuffers[0].mData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mDataByteSize = pcmBufferList->mBuffers[0].mDataByteSize;
    *ioNumberDataPackets = pcmBufferList->mBuffers[0].mDataByteSize / 2;
    
    return 0;
}

- (NSMutableData*)convertPCMToAAC:(void*)inInputData numberBytes:(UInt32)inNumberBytes {
    try {
        AudioBufferList bufferList;
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0].mNumberChannels = 1;
        bufferList.mBuffers[0].mData = self.outputBuffer;
        bufferList.mBuffers[0].mDataByteSize = self.maxPacketSize;
        
        AudioBufferList pcmBufferList;
        pcmBufferList.mBuffers[0].mData = inInputData;
        pcmBufferList.mBuffers[0].mDataByteSize = inNumberBytes;
        
        UInt32 packetSize = 1;
        XThrowIfError(AudioConverterFillComplexBuffer(self.converter, PCMToAACComplexInputDataProc, &pcmBufferList, &packetSize, &bufferList, self.outputPacketDescriptions), "cant set AudioConverterFillComplexBuffer");
        
        NSMutableData *audioData = [[NSMutableData alloc] init];
        [audioData appendBytes:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize];
        
        return audioData;
    } catch (CAXException e) {
		char buf[256];
		NSLog(@"Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
	}
    
    return nil;
}

@end
