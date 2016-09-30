//
//  VIMObjectMapper+Generic.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 4/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

extension VIMObjectMapper
{
    static var ErrorDomain: String { return "ObjectMapperErrorDomain" }
    
    /**
     Deserializes a response dictionary into a model object
     
     - parameter ModelType:          The type of the model object to map `responseDictionary` onto
     - parameter responseDictionary: The JSON dictionary response to deserialize
     - parameter modelKeyPath:       optionally, a nested JSON key path at which to originate parsing
     
     - throws: An NSError if parsing fails or the mapping class is invalid
     
     - returns: A deserialized object of type `ModelType`
     */
    static func mapObject<ModelType: MappableResponse>(responseDictionary: VimeoClient.ResponseDictionary, modelKeyPath: String? = nil) throws -> ModelType
    {
        guard let mappingClass = ModelType.mappingClass
        else
        {
            let description = "no mapping class found"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.ErrorDomain, code: LocalErrorCode.NoMappingClass.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
            
            throw error
        }
        
        let objectMapper = VIMObjectMapper()
        let modelKeyPath = modelKeyPath ?? ModelType.modelKeyPath
        objectMapper.addMappingClass(mappingClass, forKeypath: modelKeyPath ?? "")
        var mappedObject = objectMapper.applyMappingToJSON(responseDictionary)
        
        if let modelKeyPath = modelKeyPath
        {
            mappedObject = (mappedObject as? VimeoClient.ResponseDictionary)?[modelKeyPath]
        }
        
        guard let modelObject = mappedObject as? ModelType
        else
        {
            let description = "couldn't map to ModelType"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.ErrorDomain, code: LocalErrorCode.MappingFailed.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
            
            throw error
        }
        
        try modelObject.validateModel()
        
        return modelObject
    }
}