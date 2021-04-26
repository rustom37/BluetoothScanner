//
//  BinUtils.swift
//  BluetoothScanner
//
//  Created by Steve Rustom on 14/04/2021.
//  Copyright © 2021 Steve Rustom. All rights reserved.
//
// The Unpack() function and related functions are createed by Nicolas Seriot on 12/03/16. I deleted the functions that I do not care about and only kept the useful ones.
// Github repository: https://github.com/nst/BinUtils.git
//

import Foundation
import CoreFoundation

// MARK: protocol UnpackedType
public protocol Unpackable {}

extension NSString: Unpackable {}
extension Bool: Unpackable {}
extension Int: Unpackable {}
extension Double: Unpackable {}

// MARK: protocol DataConvertible
protocol DataConvertible {}

extension DataConvertible {

    init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else { return nil }
        self = data.withUnsafeBytes { $0.load(as: Self.self) }
    }

    init?(bytes: [UInt8]) {
        let data = Data(bytes)
        self.init(data:data)
    }

    var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Bool : DataConvertible { }

extension Int8 : DataConvertible { }
extension Int16 : DataConvertible { }
extension Int32 : DataConvertible { }
extension Int64 : DataConvertible { }

extension UInt8 : DataConvertible { }
extension UInt16 : DataConvertible { }
extension UInt32 : DataConvertible { }
extension UInt64 : DataConvertible { }

extension Float32 : DataConvertible { }
extension Float64 : DataConvertible { }

// MARK: Data extension
extension Data {
    var bytes : [UInt8] {
        return [UInt8](self)
    }
}

func readIntegerType<T:DataConvertible>(_ type:T.Type, bytes:[UInt8], loc:inout Int) -> T {
    let size = MemoryLayout<T>.size
    let sub = Array(bytes[loc..<(loc+size)])
    loc += size
    return T(bytes: sub)!
}

func readFloatingPointType<T:DataConvertible>(_ type:T.Type, bytes:[UInt8], loc:inout Int, isBigEndian:Bool) -> T {
    let size = MemoryLayout<T>.size
    let sub = Array(bytes[loc..<(loc+size)])
    loc += size
    let sub_ = isBigEndian ? sub.reversed() : sub
    return T(bytes: sub_)!
}

func isBigEndianFromMandatoryByteOrderFirstCharacter(_ format:String) -> Bool {

    guard let firstChar = format.first else { assertionFailure("empty format"); return false }

    let s = NSString(string: String(firstChar))
    let c = s.substring(to: 1)

    if c == "@" { assertionFailure("native size and alignment is unsupported") }

    if c == "=" || c == "<" { return false }
    if c == ">" || c == "!" { return true }

    assertionFailure("format '\(format)' first character must be among '=<>!'")

    return false
}

// akin to struct.calcsize(fmt)
func numberOfBytesInFormat(_ format:String) -> Int {

    var numberOfBytes = 0

    var n = 0 // repeat counter

    var mutableFormat = format

    while !mutableFormat.isEmpty {

        let c = mutableFormat.remove(at: mutableFormat.startIndex)

        if let i = Int(String(c)) , 0...9 ~= i {
            if n > 0 { n *= 10 }
            n += i
            continue
        }

        if c == "s" {
            numberOfBytes += max(n,1)
            n = 0
            continue
        }

        let repeatCount = max(n,1)

        switch(c) {

        case "@", "<", "=", ">", "!", " ":
            ()
        case "c", "b", "B", "x", "?":
            numberOfBytes += 1 * repeatCount
        case "h", "H":
            numberOfBytes += 2 * repeatCount
        case "i", "l", "I", "L", "f":
            numberOfBytes += 4 * repeatCount
        case "q", "Q", "d":
            numberOfBytes += 8 * repeatCount
        case "P":
            numberOfBytes += MemoryLayout<Int>.size * repeatCount
        default:
            assertionFailure("-- unsupported format \(c)")
        }

        n = 0
    }

    return numberOfBytes
}

func formatDoesMatchDataLength(_ format:String, data:Data) -> Bool {
    let sizeAccordingToFormat = numberOfBytesInFormat(format)
    let dataLength = data.count
    if sizeAccordingToFormat != dataLength {
        print("format \"\(format)\" expects \(sizeAccordingToFormat) bytes but data is \(dataLength) bytes")
        return false
    }

    return true
}

/*
 Unpack() should behave as Python's struct module https://docs.python.org/2/library/struct.html BUT:
 - native size and alignment '@' is not supported
 - as a consequence, the byte order specifier character is mandatory and must be among "=<>!"
 - native byte order '=' assumes a little-endian system (eg. Intel x86)
 - Pascal strings 'p' and native pointers 'P' are not supported
 */

public enum BinUtilsError: Error {
    case formatDoesMatchDataLength(format:String, dataSize:Int)
    case unsupportedFormat(character:Character)
}

/// Unpack a packed byte array. Similar to struct.unpack in Python
/// - Parameters:
///   - format: Format of the desired outmput
///   - data: the packed data byte
///   - stringEncoding: The used string Encoding.
/// - Throws: Error to throw
/// - Returns: Array of Unpackable
public func unpack(_ format:String, _ data:Data, _ stringEncoding:String.Encoding=String.Encoding.windowsCP1252) throws -> [Unpackable] {

    assert(CFByteOrderGetCurrent() == 1 /* CFByteOrderLittleEndian */, "\(#file) assumes little endian, but host is big endian")

    let isBigEndian = isBigEndianFromMandatoryByteOrderFirstCharacter(format)

    if formatDoesMatchDataLength(format, data: data) == false {
        throw BinUtilsError.formatDoesMatchDataLength(format:format, dataSize:data.count)
    }

    var a : [Unpackable] = []

    var loc = 0

    let bytes = data.bytes

    var n = 0 // repeat counter

    var mutableFormat = format

    mutableFormat.remove(at: mutableFormat.startIndex) // consume byte-order specifier

    while !mutableFormat.isEmpty {

        let c = mutableFormat.remove(at: mutableFormat.startIndex)

        if let i = Int(String(c)) , 0...9 ~= i {
            if n > 0 { n *= 10 }
            n += i
            continue
        }

        if c == "s" {
            let length = max(n,1)
            let sub = Array(bytes[loc..<loc+length])

            guard let s = NSString(bytes: sub, length: length, encoding: stringEncoding.rawValue) else {
                assertionFailure("-- not a string: \(sub)")
                return []
            }

            a.append(s)

            loc += length

            n = 0

            continue
        }

        for _ in 0..<max(n,1) {

            var o : Unpackable?

            switch(c) {

            case "c":
                let optionalString = NSString(bytes: [bytes[loc]], length: 1, encoding: String.Encoding.utf8.rawValue)
                loc += 1
                guard let s = optionalString else { assertionFailure(); return [] }
                o = s
            case "b":
                let r = readIntegerType(Int8.self, bytes:bytes, loc:&loc)
                o = Int(r)
            case "B":
                let r = readIntegerType(UInt8.self, bytes:bytes, loc:&loc)
                o = Int(r)
            case "?":
                let r = readIntegerType(Bool.self, bytes:bytes, loc:&loc)
                o = r ? true : false
            case "h":
                let r = readIntegerType(Int16.self, bytes:bytes, loc:&loc)
                o = Int(isBigEndian ? Int16(bigEndian: r) : r)
            case "H":
                let r = readIntegerType(UInt16.self, bytes:bytes, loc:&loc)
                o = Int(isBigEndian ? UInt16(bigEndian: r) : r)
            case "i":
                fallthrough
            case "l":
                let r = readIntegerType(Int32.self, bytes:bytes, loc:&loc)
                o = Int(isBigEndian ? Int32(bigEndian: r) : r)
            case "I":
                fallthrough
            case "L":
                let r = readIntegerType(UInt32.self, bytes:bytes, loc:&loc)
                o = Int(isBigEndian ? UInt32(bigEndian: r) : r)
            case "q":
                let r = readIntegerType(Int64.self, bytes:bytes, loc:&loc)
                o = Int(isBigEndian ? Int64(bigEndian: r) : r)
            case "Q":
                let r = readIntegerType(UInt64.self, bytes:bytes, loc:&loc)
                o = Int(isBigEndian ? UInt64(bigEndian: r) : r)
            case "f":
                let r = readFloatingPointType(Float32.self, bytes:bytes, loc:&loc, isBigEndian:isBigEndian)
                o = Double(r)
            case "d":
                let r = readFloatingPointType(Float64.self, bytes:bytes, loc:&loc, isBigEndian:isBigEndian)
                o = Double(r)
            case "x":
                loc += 1
            case " ":
                ()
            default:
                throw BinUtilsError.unsupportedFormat(character:c)
            }

            if let o = o { a.append(o) }
        }

        n = 0
    }

    return a
}
