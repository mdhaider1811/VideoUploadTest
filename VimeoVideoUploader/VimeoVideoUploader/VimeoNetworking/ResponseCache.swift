//
//  ResponseCache.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/29/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

/// Response cache handles the storage of JSON response dictionaries indexed by their associated `Request`.  It contains both memory and disk caching functionality
final internal class ResponseCache
{
    /**
     Stores a response dictionary for a request.
     
     - parameter responseDictionary: the response dictionary to store
     - parameter request:            the request associated with the response
     */
    func setResponse<ModelType>(responseDictionary: VimeoClient.ResponseDictionary, forRequest request: Request<ModelType>)
    {
        let key = request.cacheKey
        
        self.memoryCache.setResponseDictionary(responseDictionary, forKey: key)
        self.diskCache.setResponseDictionary(responseDictionary, forKey: key)
    }
    
    /**
     Attempts to retrieve a response dictionary for a request
     
     - parameter request:    the request for which the cache should be queried
     - parameter completion: returns `.Success(ResponseDictionary)`, if found in cache, or `.Success(nil)` for a cache miss.  Returns `.Failure(NSError)` if an error occurred.
     */
    func responseForRequest<ModelType>(request: Request<ModelType>, completion: ResultCompletion<VimeoClient.ResponseDictionary?>.T)
    {
        let key = request.cacheKey
        
        if let responseDictionary = self.memoryCache.responseDictionaryForKey(key)
        {
            completion(result: .Success(result: responseDictionary))
        }
        else
        {
            self.diskCache.responseDictionaryForKey(key) { responseDictionary in
                
                if let responseDictionary = responseDictionary
                {
                    completion(result: .Success(result: responseDictionary))
                }
                else
                {
                    completion(result: .Success(result: nil))
                }
            }
        }
    }

    /**
     Removes a response for a request
     
     - parameter request: the request for which to remove all cached responses
     */
    func removeResponseForRequest<ModelType>(request: Request<ModelType>)
    {
        let key = request.cacheKey
        
        self.memoryCache.removeResponseDictionaryForKey(key)
        self.diskCache.removeResponseDictionaryForKey(key)
    }
    
    /**
     Removes all responses from the cache
     */
    func clear()
    {
        self.memoryCache.removeAllResponses()
        self.diskCache.removeAllResponses()
    }
    
    // MARK: - Memory Cache
    
    private let memoryCache = ResponseMemoryCache()
    
    private class ResponseMemoryCache
    {
        private let cache = NSCache()
        
        private func setResponseDictionary(responseDictionary: VimeoClient.ResponseDictionary, forKey key: String)
        {
            self.cache.setObject(responseDictionary, forKey: key)
        }
        
        private func responseDictionaryForKey(key: String) -> VimeoClient.ResponseDictionary?
        {
            let object = self.cache.objectForKey(key) as? VimeoClient.ResponseDictionary
            
            return object
        }
        
        private func removeResponseDictionaryForKey(key: String)
        {
            self.cache.removeObjectForKey(key)
        }
        
        private func removeAllResponses()
        {
            self.cache.removeAllObjects()
        }
    }
    
    // MARK: - Disk Cache
    
    private let diskCache = ResponseDiskCache()
    
    private class ResponseDiskCache
    {
        private let queue = dispatch_queue_create("com.vimeo.VIMCache.diskQueue", DISPATCH_QUEUE_CONCURRENT)
        
        private func setResponseDictionary(responseDictionary: VimeoClient.ResponseDictionary, forKey key: String)
        {
            dispatch_barrier_async(self.queue) {
                
                let data = NSKeyedArchiver.archivedDataWithRootObject(responseDictionary)
                
                let fileManager = NSFileManager()
                
                let directoryURL = self.cachesDirectoryURL()
                let fileURL = self.fileURLForKey(key: key)
                
                guard let directoryPath = directoryURL.path,
                    let filePath = fileURL.path
                else
                {
                    assertionFailure("no cache path found: \(fileURL)")
                    
                    return
                }
                
                do
                {
                    if !fileManager.fileExistsAtPath(directoryPath)
                    {
                        try fileManager.createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    let success = fileManager.createFileAtPath(filePath, contents: data, attributes: nil)
                    
                    if !success
                    {
                        print("ResponseDiskCache could not store object")
                    }
                }
                catch let error
                {
                    print("ResponseDiskCache error: \(error)")
                }
            }
        }
        
        private func responseDictionaryForKey(key: String, completion: (VimeoClient.ResponseDictionary? -> Void))
        {
            dispatch_async(self.queue) {
                
                let fileURL = self.fileURLForKey(key: key)
                
                guard let filePath = fileURL.path
                    else
                {
                    assertionFailure("no cache path found: \(fileURL)")
                    
                    return
                }
                
                guard let data = NSData(contentsOfFile: filePath)
                else
                {
                    completion(nil)
                    
                    return
                }
                
                var responseDictionary: VimeoClient.ResponseDictionary? = nil
                
                do
                {
                    try ExceptionCatcher.doUnsafe
                    {
                        responseDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? VimeoClient.ResponseDictionary
                    }
                }
                catch let error
                {
                    print("error decoding response dictionary: \(error)")
                }
                
                completion(responseDictionary)
            }
        }
        
        private func removeResponseDictionaryForKey(key: String)
        {
            dispatch_barrier_async(self.queue) {
                
                let fileManager = NSFileManager()
                
                let fileURL = self.fileURLForKey(key: key)
                
                guard let filePath = fileURL.path
                    else
                {
                    assertionFailure("no cache path found: \(fileURL)")
                    
                    return
                }
                
                do
                {
                    try fileManager.removeItemAtPath(filePath)
                }
                catch
                {
                    print("could not remove disk cache for \(key)")
                }
            }
        }
        
        private func removeAllResponses()
        {
            dispatch_barrier_async(self.queue) {
                
                let fileManager = NSFileManager()
                
                guard let directoryPath = self.cachesDirectoryURL().path
                else
                {
                    assertionFailure("no cache directory")
                    
                    return
                }
                
                do
                {
                    try fileManager.removeItemAtPath(directoryPath)
                }
                catch
                {
                    print("could not clear disk cache")
                }
            }
        }
        
        // MARK: - directories
        
        private func cachesDirectoryURL() -> NSURL
        {
            guard let directory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first
            else
            {
                fatalError("no cache directories found")
            }
            
            return NSURL(fileURLWithPath: directory)
        }
        
        private func fileURLForKey(key key: String) -> NSURL
        {
            let directoryURL = self.cachesDirectoryURL()
            
            let fileURL = directoryURL.URLByAppendingPathComponent(key)
            
            return fileURL!
        }
    }
}
