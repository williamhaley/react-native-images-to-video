import Foundation
import AVFoundation
import UIKit

enum WriterError: Error {
    case assetWriter
    case outputSettings
    case errorFinishing
}

@objc(ImagesToVideo)
class ImagesToVideo: NSObject {
   
    @objc(render:withResolver:withRejecter:)
    func render(options: Dictionary<String, Any>, resolve:@escaping RCTPromiseResolveBlock, reject:@escaping RCTPromiseRejectBlock) -> Void {
        guard let width = options["width"] as? Int else {
            reject("options", "width is not a number", nil)
            return
        }
        guard let height = options["height"] as? Int else {
            reject("options", "height is not a number", nil)
            return
        }
        guard let absolutePaths = options["absolutePaths"] as? [String] else {
            reject("options", "absolute paths is not an array of urls", nil)
            return
        }
        if absolutePaths.count == 0 {
            reject("options", "absolute paths is empty", nil)
            return
        }
        guard let outputURL = allocateOutput(videoFilename: "output") else {
            reject("output", "could not allocate output file", nil)
            return
        }
        
        let images: [UIImage] = absolutePaths.map {UIImage.init(contentsOfFile: $0)! }
        let outputSize = CGSize.init(width: width, height: height)
        let videoWriter = VideoWriter.init()
        
        print("output: \(outputURL)")
        print("size: \(outputSize)")
        
        videoWriter.buildVideoFromImageArray(outputURL: outputURL, images: images, outputSize: outputSize, completion: { (err: Error?) -> Void in
            if let err = err {
                reject("writer", err.localizedDescription, err)
                return
            }

            resolve(outputURL.absoluteString)
        })
    }
}

func allocateOutput(videoFilename: String) -> URL? {
    let fileManager = FileManager.default
    
    guard var outputURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
        return nil
    }
    
    outputURL = outputURL.appendingPathComponent(videoFilename).appendingPathExtension("mp4")
    
    do {
        try FileManager.default.removeItem(atPath: outputURL.path)
    } catch _ as NSError {
        // Assume file didn't already exist.
    }

    return outputURL
}

class VideoWriter {
    let imagesPerSecond: TimeInterval = 2

    func buildVideoFromImageArray(outputURL: URL, images: [UIImage], outputSize: CGSize, completion: @escaping (Error?) -> Void) {
        guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mp4) else {
            completion(WriterError.assetWriter)
            return
        }

        let outputSettings = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : NSNumber(value: Float(outputSize.width)),
            AVVideoHeightKey : NSNumber(value: Float(outputSize.height))
        ] as [String : Any]

        guard videoWriter.canApply(outputSettings: outputSettings, forMediaType: AVMediaType.video) else {
            completion(WriterError.outputSettings)
            return
        }

        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: outputSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(outputSize.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(outputSize.height))
            ]
        )

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }

        if videoWriter.startWriting() {
            let zeroTime = CMTimeMake(value: Int64(imagesPerSecond),timescale: Int32(1))
            videoWriter.startSession(atSourceTime: zeroTime)

            assert(pixelBufferAdaptor.pixelBufferPool != nil)

            let media_queue = DispatchQueue(label: "mediaInputQueue")
            videoWriterInput.requestMediaDataWhenReady(on: media_queue, using: { () -> Void in
                let fps: Int32 = 1
                let framePerSecond: Int64 = Int64(self.imagesPerSecond)
                let frameDuration = CMTimeMake(value: Int64(self.imagesPerSecond), timescale: fps)
                var frameCount: Int64 = 0
                var appendSucceeded = true
                for image in images {
                    if (videoWriterInput.isReadyForMoreMediaData) {
                        let lastFrameTime = CMTimeMake(value: frameCount * framePerSecond, timescale: fps)
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        // Ownership of this follows the "Create Rule" but that is auto-managed in Swift so we do not need to release.
                        var pixelBuffer: CVPixelBuffer? = nil
                        let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferAdaptor.pixelBufferPool!, &pixelBuffer)
                        // Validate that the pixelBuffer is not nil and the status is 0
                        if let pixelBuffer = pixelBuffer, status == 0 {
                            self.drawImage(pixelBuffer: pixelBuffer, outputSize: outputSize, image: image)

                            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                        } else {
                            print("Failed to allocate pixel buffer")
                            appendSucceeded = false
                        }
                    }
                    if !appendSucceeded {
                        print("Failed to append to pixel buffer!")
                        break
                    }
                    frameCount += 1
                }

                videoWriterInput.markAsFinished()
                videoWriter.finishWriting { () -> Void in
                    if (videoWriter.error != nil ) {
                        completion(videoWriter.error)
                        return
                    }
                    if (videoWriter.status == AVAssetWriter.Status.failed || videoWriter.status == AVAssetWriter.Status.cancelled) {
                        completion(WriterError.errorFinishing)
                        return
                    }

                    completion(nil)
                }
            })
        }
    }

    func drawImage(pixelBuffer: CVPixelBuffer, outputSize: CGSize, image: UIImage) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let pxdata = CVPixelBufferGetBaseAddress(pixelBuffer)
        let context = CGContext(
            data: pxdata,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        let rect = CGRect(x: 0, y: 0, width: CGFloat(outputSize.width), height: CGFloat(outputSize.height))
        context!.clear(rect)

        context!.translateBy(x: 0, y: outputSize.height)
        context!.scaleBy(x: 1, y: -1)

        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }
}
