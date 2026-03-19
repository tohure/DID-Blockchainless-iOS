// AppLogger.swift
// DIDBlockchainlessDemo
//
// Logging centralizado con os.Logger — solo visible en builds DEBUG.
// Equivalente a AppLogger.kt de Android.

import Foundation
import os.log

/// Loggers categorizados por subsistema, usando `os.Logger` (structured logging).
///
/// En builds **Release**, `os.Logger` no escribe a la consola de texto plano y
/// los mensajes privados son redactados automáticamente por el sistema.
/// Equivalente al comportamiento de `AppLogger` en Android que solo loguea en DEBUG.
enum AppLogger {
    nonisolated static func crypto() -> Logger { Logger(subsystem: "dev.tohure.DIDBlockchainlessDemo", category: "crypto") }
    nonisolated static func did() -> Logger { Logger(subsystem: "dev.tohure.DIDBlockchainlessDemo", category: "did") }
    nonisolated static func network() -> Logger { Logger(subsystem: "dev.tohure.DIDBlockchainlessDemo", category: "network") }
    nonisolated static func storage() -> Logger { Logger(subsystem: "dev.tohure.DIDBlockchainlessDemo", category: "storage") }
    nonisolated static func ui() -> Logger { Logger(subsystem: "dev.tohure.DIDBlockchainlessDemo", category: "ui") }
}

// MARK: - Nivel de debug condicional

extension Logger {
    /// Loguea solo en builds DEBUG. En Release es un no-op en tiempo de compilación.
    nonisolated func debug_only(_ message: String) {
        #if DEBUG
        debug("\(message)")
        #endif
    }
}
