// Base58.swift
// DIDBlockchainlessDemo
//
// Codificador Base58btc con el alfabeto Bitcoin.
// Equivalente exacto a Base58.kt de Android — mismo algoritmo, mismo alfabeto.

import Foundation

/// Codificador Base58btc para la derivación did:key.
///
/// Base58 es Base64 sin los caracteres visualmente ambiguos:
/// `0` (cero), `O` (O mayúscula), `I` (i mayúscula), `l` (l minúscula),
/// y sin `+` ni `/`. El resultado es más legible y copiable.
///
/// Referencia: https://en.bitcoin.it/wiki/Base58Check_encoding
enum Base58: Sendable {

    private static let alphabet =
        Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

    /// Codifica `input` en Base58btc.
    /// Implementación por división sucesiva identica a la de Android / Python.
    nonisolated static func encode(_ input: Data) -> String {
        let bytes = Array(input)

        // Contar ceros iniciales (se mapean al primer carácter del alfabeto '1')
        let leadingZeros = bytes.prefix(while: { $0 == 0 }).count

        // División sucesiva del número big-endian en base 58
        var digits: [Int] = [0]
        for byte in bytes {
            var carry = Int(byte)
            for j in digits.indices.reversed() {
                carry += digits[j] * 256
                digits[j] = carry % 58
                carry /= 58
            }
            while carry > 0 {
                digits.insert(carry % 58, at: 0)
                carry /= 58
            }
        }

        // Eliminar ceros del frente (ya compensados por leading zeros)
        let encoded = digits.drop(while: { $0 == 0 }).map { alphabet[$0] }
        let prefix = Array(repeating: alphabet[0], count: leadingZeros)

        return String(prefix + encoded)
    }
}
