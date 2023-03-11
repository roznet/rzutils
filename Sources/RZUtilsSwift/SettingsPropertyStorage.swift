//
//  File.swift
//  
//
//  Created by Brice Rosenzweig on 10/03/2023.
//

import Foundation
import RZUtils

public struct SecureKeyChainItem {
    public enum SecureKeyChainItemError : Error {
        case itemNotFound
        case invalidData
        case unhandledError(status: OSStatus)
    }
   
    private let service : String // service identifier
    private let accessGroup: String? //
    
    public let key : String // Will use account for the key
    public var value : Data? {
        get {
            return try? self.readItem()
        }
        set {
            if let val = newValue {
                do {
                    try self.addItem(item: val)
                }catch (SecureKeyChainItemError.itemNotFound){
                    do {
                        try self.updateItem(item: val)
                    }catch{
                        
                    }
                }catch{
                    
                }
            }else{
                do {
                    try self.deleteItem()
                }catch{
                    
                }
            }
        }
    }

    public init(key : String, service : String, accessGroup : String? = nil){
        self.service = service
        self.key = key
        self.accessGroup = accessGroup
    }
    
    var query : [String: Any] {
        var rv : [String : Any] = [:]
        rv[ kSecClass as String] = kSecClassGenericPassword
        rv[ kSecAttrAccount as String] = key
        rv[ kSecAttrService as String] = service
        if let accessGroup = self.accessGroup {
            rv[ kSecAttrAccessGroup as String] = accessGroup
        }
        return rv
        
    }
    func readItem() throws -> Data {
        var query = self.query
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var item : CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw SecureKeyChainItemError.itemNotFound }
        guard status == errSecSuccess else { throw SecureKeyChainItemError.unhandledError(status: status) }
        
        guard let existingItem = item as? [String : Any],
              let itemData = existingItem[kSecValueData as String] as? Data
        else {
            throw SecureKeyChainItemError.invalidData
        }
        return itemData
    }
    
    func addItem(item : Data) throws {
        var query = self.query
        query[ kSecValueData as String] = item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw SecureKeyChainItemError.unhandledError(status: status)}
    }
    
    func deleteItem() throws {
        let query = self.query
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw SecureKeyChainItemError.unhandledError(status: status)}
    }
    
    func updateItem(item : Data) throws {
        let query = self.query
        var attributes : [String:Any] = [:]
        attributes[kSecValueData as String] = item
        attributes[kSecAttrAccount as String] = key
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else { throw SecureKeyChainItemError.itemNotFound }
        guard status == errSecSuccess else { throw SecureKeyChainItemError.unhandledError(status: status)}
    }
}

@propertyWrapper
public struct CodableSecureStorage<Key : RawRepresentable<String>, Type : Codable> {
    private var keyChainItem : SecureKeyChainItem
    
    public init(key : Key, service : String, accessGroup : String? = nil){
        self.keyChainItem = SecureKeyChainItem(key: key.rawValue, service: service, accessGroup: accessGroup)
    }
    
    public var wrappedValue : Type? {
        get {
            if let data = self.keyChainItem.value,
               let decoded = try? JSONDecoder().decode(Type.self, from: data) {
                return decoded
            }
            return nil
        }
        set {
            if newValue != nil, let data = try? JSONEncoder().encode(newValue) {
                self.keyChainItem.value = data
            }else{
                self.keyChainItem.value = nil
            }
        }
    }
}

@propertyWrapper
public struct UserStorage<Key : RawRepresentable<String>, Type> {
    private let key : String
    private let defaultValue : Type
    public init(key : Key, defaultValue : Type){
        self.key = key.rawValue
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue : Type {
        get {
            UserDefaults.standard.object(forKey: key) as? Type ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
public struct CodableStorage<Key : RawRepresentable<String>, Type : Codable> {
    private let key : String
    
    public init(key : Key){
        self.key = key.rawValue
    }
    
    public var wrappedValue : Type? {
        get {
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode(Type.self, from: data) {
                return decoded
            }
            return nil
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }else{
                UserDefaults.standard.set(nil, forKey: key)
            }
        }
    }
}
@propertyWrapper
public struct UnitStorage<Key : RawRepresentable<String>,UnitType : Dimension> {
    private let key : String
    private let defaultValue : UnitType
    public init(key : Key, defaultValue : UnitType){
        self.key = key.rawValue
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue : UnitType {
        get {
            if let gcUnitKey = UserDefaults.standard.object(forKey: key) as? String{
                return (GCUnit(forKey: gcUnitKey)?.foundationUnit as? UnitType) ?? defaultValue
            }else{
                return defaultValue
            }
        }
        set {
            if let gcUnit = newValue.gcUnit {
                UserDefaults.standard.set(gcUnit.key, forKey: key)
            }
        }
    }
}


@propertyWrapper
public struct EnumStorage<Key : RawRepresentable<String>, Type : RawRepresentable > {
    private let key : String
    private let defaultValue : Type

    public init(key : Key, defaultValue : Type){
        self.key = key.rawValue
        self.defaultValue = defaultValue
    }
    
    public var wrappedValue : Type {
        get {
            if let raw = UserDefaults.standard.object(forKey: key) as? Type.RawValue {
                return Type(rawValue: raw) ?? defaultValue
            }else{
                return defaultValue
            }
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }

}

