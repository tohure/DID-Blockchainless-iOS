// Data+Hex.swift
// DIDBlockchainlessDemo
//
// Extensiones para codificación/decodificación hexadecimal.
// Equivalente a la lógica hex manual de DIDKeyManager.kt de Android.

import Foundation

extension Data {

    /// Codifica los bytes en string hexadecimal en minúsculas (sin prefijo 0x).
    var hexEncodedString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    /// Decodifica un string hexadecimal en Data.
    /// - Parameter hexString: String con longitud par, sin prefijo 0x.
    /// - Returns: `nil` si la longitud es impar o contiene caracteres no hex.
    init?(hexEncoded hexString: String) {
        guard hexString.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(hexString.count / 2)
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else { return nil }
            bytes.append(byte)
            index = nextIndex
        }
        self = Data(bytes)
    }
}
