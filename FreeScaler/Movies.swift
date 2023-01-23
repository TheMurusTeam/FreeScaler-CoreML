//
//  VideoConverter.swift
//  testUpscaleVideo
//
//  Created by Opossum on 10/11/22.
//

import Foundation
import AVFoundation
import CoreMedia
import AppKit

class VideoConverter : NSObject{
    
    static let shared = VideoConverter()
    private override init() {}
    
    
    func upscale(urlInput: URL, urlOutput: URL, completion: @escaping ((String) -> Void)) {
        
        //MARK: code
        let dispatchGroup = DispatchGroup()
        let mainQueue = DispatchQueue(label: "mainQueue")
        let audioQueue = DispatchQueue(label: "audioQueue")
        let videoQueue = DispatchQueue(label: "videoQueue")
        
        let asset = AVURLAsset(url: urlInput)
        
        if FileManager.default.fileExists(atPath: urlOutput.path) {
            do {
                try FileManager.default.removeItem(atPath: urlOutput.path)
            } catch {
                fatalError("file not found")
            }
        }
        
        asset.loadValuesAsynchronously(forKeys: []) {
            
            mainQueue.async {
                let assetReader: AVAssetReader
                let assetWriter: AVAssetWriter
                
                do {
                    assetReader = try AVAssetReader(asset: asset)
                    assetWriter = try AVAssetWriter(outputURL: urlOutput, fileType: AVFileType.mov)
                } catch {
                    return
                }
                
                var audio = false
                var assetAudioTrack :  AVAssetTrack? = nil
                var assetReaderAudioOutput : AVAssetReaderTrackOutput? = nil
                var assetWriterAudioInput : AVAssetWriterInput? = nil
                // MARK: - Audio Setting
                if let assetAudio = asset.tracks(withMediaType: .audio).first  {
                    assetAudioTrack = assetAudio
                    audio = true
                    let readerAudioSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM]
                     assetReaderAudioOutput = AVAssetReaderTrackOutput(track: assetAudioTrack!, outputSettings: readerAudioSettings)
                    assetReaderAudioOutput?.alwaysCopiesSampleData = true
                    if assetReader.canAdd(assetReaderAudioOutput!)  {
                        assetReader.add(assetReaderAudioOutput!)
                    }
                }
                    
                
                    
                    
                    
                if audio {
                    let writerAudioSettings: [String: Any] = [
                        AVFormatIDKey         : kAudioFormatMPEG4AAC,
                        AVEncoderBitRateKey   : 128000,
                        AVSampleRateKey       : 44100,
                        AVNumberOfChannelsKey : 2
                    ]
                    
                     assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: writerAudioSettings)
                    
                    if assetWriter.canAdd(assetWriterAudioInput!) {
                        assetWriter.add(assetWriterAudioInput!)
                    }
                }
                
                // MARK: - Video Setting
                guard let assetVideoTrack = asset.tracks(withMediaType: .video).first else {
                    return
                }
                let framesPerSecond = assetVideoTrack.nominalFrameRate
                let totaltime  = asset.duration
                
                DispatchQueue.main.async {
                    (viewCtrl["single"] as? FSMovieViewController)?.totaltime.stringValue = totaltime.seconds.description
                    (viewCtrl["single"] as? FSMovieViewController)?.progr.doubleValue = 0
                    (viewCtrl["single"] as? FSMovieViewController)?.progr.maxValue = totaltime.seconds
                }
                
                
                let readerVideoSettings: [String: Any] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]
                
                let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: assetVideoTrack, outputSettings: readerVideoSettings)
                assetReaderVideoOutput.supportsRandomAccess = true
                assetReaderVideoOutput.alwaysCopiesSampleData = true
                if assetReader.canAdd(assetReaderVideoOutput) {
                    assetReader.add(assetReaderVideoOutput)
                }
                let trackDimensions = assetVideoTrack.naturalSize
                
                
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey  : AVVideoCodecType.h264,
                    AVVideoWidthKey  : trackDimensions.width * 4,
                    AVVideoHeightKey : trackDimensions.height * 4
                ]
                
                let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: nil)
                assetWriterVideoInput.expectsMediaDataInRealTime = false
                assetWriterVideoInput.transform = assetVideoTrack.preferredTransform
                if assetWriter.canAdd(assetWriterVideoInput) {
                    assetWriter.add(assetWriterVideoInput)
                }
                
                // MARK: - Upscale
                guard assetReader.startReading() else {
                    completion("error")
                    return
                }
                guard assetWriter.startWriting() else {
                    completion("error")
                    return
                }
                
                assetWriter.startSession(atSourceTime: .zero)
                if audio {
                    dispatchGroup.enter()
                    assetWriterAudioInput!.requestMediaDataWhenReady(on: audioQueue) {
                        while assetWriterAudioInput!.isReadyForMoreMediaData {
                            if let sampleBuffer = assetReaderAudioOutput!.copyNextSampleBuffer() {
                                let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                                //print("completato audio:\( presentationTime.seconds)")
                                while !assetWriterAudioInput!.isReadyForMoreMediaData { usleep(10) }
                                assetWriterAudioInput!.append(sampleBuffer)
                            } else {
                                assetWriterAudioInput!.markAsFinished()
                                dispatchGroup.leave()
                                break
                            }
                        }
                        
                    }
                }
                var frameCounter = 0
                dispatchGroup.enter()
                assetWriterVideoInput.requestMediaDataWhenReady(on: videoQueue) {
                  
                    while assetWriterVideoInput.isReadyForMoreMediaData {
                        if let sampleBuffer = assetReaderVideoOutput.copyNextSampleBuffer() {
                            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                            //print("completato video:\( presentationTime.seconds)")
                            
                            DispatchQueue.main.async {
                                (viewCtrl["single"] as? FSMovieViewController)?.timelabel.doubleValue = presentationTime.seconds
                                (viewCtrl["single"] as? FSMovieViewController)?.progr.doubleValue = presentationTime.seconds
                            }
                            
                            if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                                if  let bufferupscaled =   Upscaler.shared.predictPixelBuffer(buffer: imageBuffer){
                                    let frameTime = CMTimeMake(value: Int64(frameCounter), timescale: Int32(framesPerSecond))
                                    ///qui va appsto il frame upscalato
                                    while !assetWriterVideoInput.isReadyForMoreMediaData { usleep(10) }
                                    assetWriterAdaptor.append(bufferupscaled, withPresentationTime: frameTime)
                                    frameCounter = frameCounter + 1
                                } else {
                                    // ERROR
                                    //print("ERROR, NO FRAME")
                                    return
                                }
                               /* let frameTime = CMTimeMake(value: Int64(frameCounter), timescale: Int32(framesPerSecond))
                                ///qui va appsto il frame upscalato
                                while !assetWriterVideoInput.isReadyForMoreMediaData { usleep(10) }
                                assetWriterAdaptor.append(imageBuffer, withPresentationTime: frameTime)*/
                               
                                
                                
                                
                                /*
                                if modelname == "TF2" {
                                    print(modelname)
                                    if  let bufferupscaled =   UpscalerML.shared.predictWithMultiarray(buffer: imageBuffer){
                                        let frameTime = CMTimeMake(value: Int64(frameCounter), timescale: Int32(framesPerSecond))
                                        ///qui va appsto il frame upscalato
                                        assetWriterAdaptor.append(bufferupscaled, withPresentationTime: frameTime)
                                    }
                                }else{
                                    if  let bufferupscaled =   UpscalerML.shared.predictPixelBuffer(buffer: imageBuffer){
                                        let frameTime = CMTimeMake(value: Int64(frameCounter), timescale: Int32(framesPerSecond))
                                        ///qui va appsto il frame upscalato
                                        assetWriterAdaptor.append(bufferupscaled, withPresentationTime: frameTime)
                                    }
                                }
                                */
                                
                            }
                            if assetReader.status.rawValue != 1 {
                                                         usleep(50000)
                            }
                            
                            
                        } else {
                            assetWriterVideoInput.markAsFinished()
                            dispatchGroup.leave()
                            break
                        }
                    }
                    
                }
                
                dispatchGroup.notify(queue: mainQueue, work: DispatchWorkItem {
                    assetWriter.finishWriting {
                        //print("Done")
                        completion("done")
                    }
                })
            }
        }
    }
    
    
    
}

