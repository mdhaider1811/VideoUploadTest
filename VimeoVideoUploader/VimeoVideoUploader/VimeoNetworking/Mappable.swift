//
//  MappableResponse.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/22/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

private let DefaultModelKeyPath = "data"

/**
 *  `MappableResponse` represents an object that can be automatically deserialized from a JSON response dictionary to a model object.  Conformance to this protocol allows a type to participate as the `ModelType` in a `Request`.  You should not adopt this protocol directly, but should subclass `VIMModelObject` for new models.  `VIMModelObject` as well as arrays with an element type of `VIMModelObject` conform to `MappableResponse`.  `VIMNullResponse` also conforms to this protocol, which allows for the representation of successful requests that intentionally return no response dictionary.
 */
public protocol MappableResponse
{
    /// The base class of the mapped response, used for restricting generic parameters to the base model class
    associatedtype Element
    
    /// Returns the class type used by `VIMObjectMapper` to deserialize the response
    static var mappingClass: AnyClass? { get }
    
    /// Optionally returns a nested JSON key to reference for mapping
    static var modelKeyPath: String? { get }
    
    /**
     Implemented by model objects to ensure that their own values are valid for use, called as a step in model object parsing, parsing will fail if this throws an error
     
     - throws: An error if a model object's values are somehow invalid.
     */
    func validateModel() throws
}

/**
 *  `VIMModelObject` conformance to `MappableResponse` enables all model objects derived from `VIMModelObject` to participate as the `ModelType` in a `Request`.
 */
extension VIMModelObject: MappableResponse
{
    public typealias Element = VIMModelObject
    
    public static var mappingClass: AnyClass?
    {
        return self
    }
    
    public static var modelKeyPath: String?
    {
        return nil
    }
    
    public func validateModel() throws
    {
        var error: NSError? = nil
        
        self.validateModel(&error)
        
        if let error = error
        {
            throw error
        }
    }
}

/**
 *  `Array` conformance to `MappableResponse` enables arrays of any model object type to participate as the `ModelType` in a `Request`.
 */
extension Array: MappableResponse
{
    // The default implementation for all arrays will return no mapping class or model key path
    // Only if Element itself is a VIMModelObject will the values be returned
    // TODO: This is because we can't restrict the generic type if we're
    // extending a type with generics to conform to a protocol [RH]
    
    public static var mappingClass: AnyClass?
    {
        if Element.self is VIMModelObject.Type
        {
            return (Element.self as! AnyClass)
        }
        
        return nil
    }
    
    public static var modelKeyPath: String?
    {
        if Element.self is VIMModelObject.Type
        {
            return DefaultModelKeyPath
        }
        
        return nil
    }
    
    public func validateModel() throws
    {
        for model in self
        {
            guard let model = model as? VIMModelObject
            else
            {
                let description = "Mappable array does not have an element type inheriting from VIMModelObject"
                let error = NSError(domain: VIMModelObjectErrorDomain, code: VIMModelObjectValidationErrorCode, userInfo: [NSLocalizedDescriptionKey: description])
                
                throw error
            }
            
            var error: NSError? = nil
            
            model.validateModel(&error)
            
            if let error = error
            {
                throw error
            }
        }
    }
}

/**
 *  `VIMNullResponse` is a model object containing no information. This allows for the representation of successful requests that intentionally return no response dictionary.
 */
public class VIMNullResponse: MappableResponse
{
    public typealias Element = VIMNullResponse
    
    public static var mappingClass: AnyClass?
    {
        return self
    }
    
    public static var modelKeyPath: String?
    {
        return nil
    }
    
    public func validateModel() throws
    {
        // NO-OP: a null response object is always valid
    }
}
