//
//  VideoLoaderManager.swift
//  YoudaoK12
//
//  Created by ght on 2019/1/28.
//  Copyright © 2019 youdao. All rights reserved.
//

import Foundation
import MediaPlayer
/**
 *V1.0 做简单的缓存策略,直接下载存在本地,使用AVAssetDownloadTask & assetCache,最大为10
 V2.0 做边下边播缓存， 使用AVAssetResourceLoader,参考AVPlayerCacheSupport  和 VIMediaCache
 */

// V1.0
let videoPathKey = "YK12_assetPath"
//@available (iOS 10.0,*)
open class BMVideoLoadManager : NSObject {
    
    static let shared = BMVideoLoadManager()
    
    private var downloadSession : AVAssetDownloadURLSession?
    private var downloaingTaskDict:[URL:AVAssetDownloadTask] = [:]
    
    private var downloadingLock : NSLock {
        let lock = NSLock()
        return lock
    }
    
    private func  setupDownload() {
        if downloadSession == nil {
            let configuration = URLSessionConfiguration.background(withIdentifier: "yk12.backgroundsession")
            configuration.sessionSendsLaunchEvents = false
            downloadSession =
                AVAssetDownloadURLSession(configuration: configuration,assetDownloadDelegate: self,
                                          delegateQueue: OperationQueue.main)
        }
    }
    
   override init() {
        super.init()
        setupDownload()
    }
    
    deinit {
        downloadSession?.invalidateAndCancel()
    }
    
    //对外
    func loadVideo(url:URL, videoTitle:String) -> AVURLAsset {
        //1 read cache
        //2 if no, start videodownloadOpretion,retun nil,and play online steam
        guard let assetPathDict = UserDefaults.standard.value(forKey:videoPathKey) as? Dictionary<String, String> else {
            let asset = startDownloadTask(url)
            return asset
        }
        guard let assetPath =  assetPathDict[url.absoluteString] else {
            let asset = startDownloadTask(url)
            return asset
        }
        let baseURL = URL(fileURLWithPath: NSHomeDirectory())
        let assetURL = baseURL.appendingPathComponent(assetPath)
        var asset = AVURLAsset(url: assetURL)
        if #available(iOS 10.0, *) {
            if let cache = asset.assetCache
                //, cache.isPlayableOffline
            {
                return asset
            } else {
                asset = startDownloadTask(url)
                return asset
            }
        } else {
            return AVURLAsset(url: url)
        }
    }
    
    func deleteVideoCache() {
        do {
            let userDefaults = UserDefaults.standard
            if let assetPathDict = userDefaults.value(forKey:videoPathKey) as? Dictionary<String, String> {
                try assetPathDict.forEach { (arg0) in
                    let (_, value) = arg0
                    let baseURL = URL(fileURLWithPath: NSHomeDirectory())
                    let assetURL = baseURL.appendingPathComponent(value)
                    try FileManager.default.removeItem(at: assetURL)
                }
                userDefaults.removeObject(forKey:videoPathKey)
            }
        } catch {
            //DDLogError("An error occured deleteVideoCach")
        }
    }
    
    private func startDownloadTask(_ url:URL) -> AVURLAsset {
        let asset = AVURLAsset(url: url)
        if #available(iOS 10.0, *) {
            if !isTaskExist(url) {
                let downloadTask = downloadSession!.makeAssetDownloadTask(asset: asset, assetTitle:"lslls", assetArtworkData: nil, options: nil)
                downloadTask?.resume()
                downloadingLock.lock()
                downloaingTaskDict[url] = downloadTask
                downloadingLock.unlock()
            }
        }
        return asset
    }
    
    private func isTaskExist(_ url:URL) -> Bool {
        var isExist = false
        downloadingLock.lock()
        if let task = downloaingTaskDict[url] {
            //task.resume()
            isExist = true
        }
        downloadingLock.unlock()
        return isExist
    }
    
    private func removeTask(_ url:URL) {
        downloadingLock.lock()
        downloaingTaskDict.removeValue(forKey: url)
        downloadingLock.unlock()
    }
}

@available(iOS 10.0, *)
extension BMVideoLoadManager : AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard assetDownloadTask.urlAsset.url else {
            return
        }
        removeTask(assetDownloadTask.urlAsset.url)
        let userDefaults = UserDefaults.standard
        if let pathList = userDefaults.value(forKey:videoPathKey) as? Dictionary<String, String> {
            var videoPathList : [String:String] = pathList
            videoPathList[assetDownloadTask.urlAsset.url.absoluteString] = location.relativePath
            UserDefaults.standard.set(videoPathList, forKey:videoPathKey)
        } else {
            var videoPathList = [String:String]()
            videoPathList[assetDownloadTask.urlAsset.url.absoluteString] = location.relativePath
            UserDefaults.standard.set(videoPathList, forKey:videoPathKey)
        }
    }
    
   /* func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard error == nil else {
            return
        }
        guard let task = task as? AVAssetDownloadTask else { return }
        removeTask(task.urlAsset.url)
        //startDownloadTask(task.urlAsset.url)
    }*/
}
