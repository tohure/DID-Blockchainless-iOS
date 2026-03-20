# DID Blockchainless Demo — iOS

App iOS nativa (SwiftUI) que implementa generación de identidades descentralizadas (DID)
con gestión segura de claves y Verifiable Credentials, sin blockchain.

---

## Requisitos

| Requisito | Valor | Motivo |
|---|---|---|
| Xcode | 16.0+ | Swift 5.10, Observation framework |
| iOS mínimo | 17.0 | `@Observable`, `NavigationStack` |
| Hardware recomendado | iPhone XS (2018)+ | Secure Enclave presente |
| Swift Package | `swift-secp256k1` | secp256k1 (no soportada por CryptoKit nativo) |

> **Nota:** El Secure Enclave existe en **todos los dispositivos con iOS 17+**  
> (presente desde iPhone 5S / 2013). Equivale a StrongBox/TEE de Android.

---

## Configuración

### 1. Clonar y abrir

```bash
git clone <repo>
open DIDBlockchainlessDemo.xcodeproj
```

### 2. Configurar BASE_URL

Las credenciales de entorno viven en `Secrets.xcconfig` (gitignored), incluido desde `Debug.xcconfig` y `Release.xcconfig`:

```bash
cp Secrets.xcconfig.example Secrets.xcconfig
# Edita Secrets.xcconfig y ajusta BASE_URL
```

> `Secrets.xcconfig` está en `.gitignore` — nunca se sube al repositorio.  
> Equivalente al `local.properties` de Android.

### 3. Añadir `swift-secp256k1` en Xcode

En Xcode:
1. **File → Add Package Dependencies...**
2. URL: `https://github.com/21-DOT-DEV/swift-secp256k1`
3. Versión mínima: `0.22.0`
4. Producto a añadir al target: **`P256K`** (el módulo cambió de nombre en v0.22)

### 4. Configurar Info.plist

En **Target → Info → Custom iOS Target Properties** añadir:
- `NSFaceIDUsageDescription` — descripción para Face ID
- `BASE_URL` → valor `$(BASE_URL)` (inyectado desde xcconfig en tiempo de build)

### 5. Simulator vs Dispositivo Físico

El código en `CryptoConfig.swift` detecta automáticamente el entorno:
- **Simulator**: Desactiva biometría (`useBiometrics = false`) para evitar prompts Face ID simulados y facilitar el desarrollo.
- **Dispositivo**: Fuerza biometría (`true`) y usa el Secure Enclave real.

---

## Arquitectura

```
iOS/                            Android equivalente
─────────────────────────────   ───────────────────
Config/AppConfig.swift       ←→ BuildConfig.BASE_URL
Config/CryptoConfig.swift    ←→ CryptoConfig.kt

Crypto/SecurityLevel.swift   ←→ SecurityLevel.kt
Crypto/KeychainHelper.swift  ←→ KeystoreHelper.kt
Crypto/CryptoManager.swift   ←→ CryptoManager.kt

DID/Base58.swift             ←→ Base58.kt
DID/DIDKeyManager.swift      ←→ DIDKeyManager.kt
DID/JWTSigner.swift          ←→ JwtSigner.kt
DID/ProofJWTBuilder.swift    ←→ ProofJWTBuilder.kt
DID/VPJWTBuilder.swift       ←→ VpJWTBuilder.kt

Data/Models/Models.swift     ←→ data/model/*.kt
Data/Network/APIClient.swift ←→ NetworkClient.kt (OkHttp+Retrofit)
Data/Network/APIEndpoint.swift ←→ CredentialApi.kt (Retrofit interface)
Data/Repository/...          ←→ CredentialRepository.kt

Storage/CredentialStore.swift ←→ CredentialStore.kt (SharedPreferences)

UI/ViewModels/BiometricAwareViewModel.swift ←→ BiometricAwareViewModel.kt
UI/ViewModels/DIDViewModel.swift            ←→ DidViewModel.kt
UI/ViewModels/RSAViewModel.swift            ←→ RsaViewModel.kt
UI/Screens/HomeScreen.swift                 ←→ HomeScreen.kt
UI/Screens/DIDScreen.swift                  ←→ DidScreen.kt
UI/Screens/RSAScreen.swift                  ←→ RsaScreen.kt
```

### Patrón de estado (MVVM)

| Android | iOS |
|---|---|
| `ViewModel` + `StateFlow` | `@Observable` class + `@State` (iOS 17) |
| `Coroutines` + `Dispatchers.IO` | Swift Concurrency `async/await` + `actor` |
| `viewModelScope.launch {}` | `Task { [weak self] in }` en `@MainActor` |
| `BiometricPrompt` callback | `LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` |

---

## Seguridad

### Clave secp256k1 (DID)

El Secure Enclave de iOS **no soporta secp256k1** (solo P-256).  
Por ello usamos el mismo esquema que Android:

```
swift-secp256k1 (libsecp256k1)
    │  genera par de claves en RAM
    ▼
Clave AES-256 (wrap key)
    │  generada por CryptoKit, guardada en Keychain
    │  protegida con kSecAccessControlBiometryCurrentSet
    │  respaldada por Secure Enclave
    ▼
Clave privada secp256k1 cifrada con AES-256-GCM
    │  guardada en Keychain (sin biometría — ya cifrada)
    ▼
Clave pública (33 bytes comprimida)
    │  guardada en Keychain (sin biometría — no sensible)
    ▼
DID: did:key:z<base58btc([0xe7,0x01] + pub_compressed)>
```

La clave privada **nunca sale sin cifrar del Keychain**. Tras cada firma:
- Los bytes se limpian de RAM con `defer { privBytes = Data(zeros) }`.
- **Firma Compacta (R‖S):** Se usa obligatoriamente `signature.compactRepresentation` (64 bytes) para asegurar compatibilidad con el servidor y Android.

### Cifrado de Verifiable Credentials (AES-256-GCM)

> **Por qué solo AES y no RSA+AES como en Android:**  
> En iOS el Keychain ya protege la clave simétrica a nivel de hardware
> (Secure Enclave backed). No necesitamos el paso intermedio de RSA que
> usa Android. El resultado es igual de seguro, más eficiente, y más simple.

```
Clave AES-256-GCM (32 bytes)
    │  en Keychain con kSecAccessControlBiometryCurrentSet
    ▼
Payload = [nonce(12)] + [ciphertext] + [auth_tag(16)]
    │  → Base64URL para almacenamiento
    ▼
Keychain: kSecClassGenericPassword  (no iCloud, solo este dispositivo)
```

### Biometría

| Aspecto | Valor |
|---|---|
| API | `kSecAccessControlBiometryCurrentSet` |
| Política LAContext | `deviceOwnerAuthenticationWithBiometrics` |
| Fallback a PIN | **No** — equivale a Android sin `setDeviceCredentialAllowed` |
| Invalida por cambio biométrico | **Sí** — automático con `BiometryCurrentSet` |
| Face ID / Touch ID | Acepta la biometría disponible en el hardware |

### Tabla resumen Android vs iOS

| Aspecto | Android | iOS |
|---|---|---|
| Clave secp256k1 | BouncyCastle + AES-GCM wrap en Keystore | swift-secp256k1 + AES-GCM wrap en Keychain |
| Resistencia hardware | StrongBox / TEE | Secure Enclave |
| Biometría | `BIOMETRIC_STRONG` (clase 3) | `BiometryCurrentSet` |
| Sin PIN | `AUTH_BIOMETRIC_STRONG` | `.deviceOwnerAuthenticationWithBiometrics` |
| VCs storage | SharedPreferences (payload ya cifrado) | Keychain `kSecClassGenericPassword` |
| Logging DEBUG | `AppLogger` only | `os.Logger` (redactado en Release) |

---

## Flujos

### Flujo DID completo

```
Usuario: "Generar claves"
    ↓ swift-secp256k1.generate()
    ↓ AES-GCM encrypt(priv) con wrap key del Keychain (biometría)
    ↓ Keychain.save(encPriv, pub)
    ↓ DID = "did:key:z" + base58([0xe7,0x01] + pub_compressed)

Usuario: "Solicitar credencial"
    ↓ POST /dids/register { did, client_id }
    ↓ GET  /credentials/nonce?holder_did=...  → nonce
    ↓ ProofJWT.build (ES256K, nonce, subject_claims)
    ↓ POST /credentials/issue { holder_did, proof }
    ↓ CryptoManager.encrypt(credential_jwt)
    ↓ CredentialStore.save("demo_vc", encrypted)

Usuario: "Verificar VP"
    ↓ CredentialStore.load("demo_vc") → encrypted
    ↓ CryptoManager.decrypt(encrypted) → credential_jwt
    ↓ VPJWTBuilder.build (credential_jwt, audience)
    ↓ POST /credentials/verify { vp_jwt }
    ↓ { valid: true, holder_did: "did:key:z..." }
```

---

## Tests

### Unitarios (corren en Simulator)

```bash
xcodebuild test \
  -scheme DIDBlockchainlessDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Cubren:
- `Base58Tests` — encoding con vectores conocidos
- `DataExtensionTests` — roundtrip Base64URL (RFC 4648 §5) y hex encoding
- `JWTStructureTests` — estructura de header/payload JWT

### Integración (dispositivo físico requerido)

> El Simulator **no emula el Secure Enclave ni la biometría real**.  
> Las pruebas de Keychain biométrico requieren un iPhone o iPad físico.

---

## Estructura de archivos

```
DIDBlockchainlessdemo/
├── Secrets.xcconfig                 # (gitignored) BASE_URL real
├── Secrets.xcconfig.example         # Template — sí se commitea
├── Debug.xcconfig                   # Incluye Secrets.xcconfig + flags DEBUG
├── Release.xcconfig                 # Incluye Secrets.xcconfig + optimizaciones
├── DIDBlockchainlessDemo.xcodeproj/
├── DIDBlockchainlessDemo/
│   ├── DIDBlockchainlessDemoApp.swift
│   ├── Config/
│   │   ├── AppConfig.swift          # BASE_URL desde Info.plist
│   │   └── CryptoConfig.swift       # USE_BIOMETRICS, timeouts
│   ├── Crypto/
│   │   ├── SecurityLevel.swift
│   │   ├── KeychainHelper.swift     # actor: CRUD Keychain + biometría
│   │   └── CryptoManager.swift      # AES-256-GCM para VCs
│   ├── DID/
│   │   ├── Base58.swift
│   │   ├── DIDKeyManager.swift      # actor: secp256k1 + ES256K
│   │   ├── JWTSigner.swift
│   │   ├── ProofJWTBuilder.swift
│   │   └── VPJWTBuilder.swift
│   ├── Data/
│   │   ├── Models/Models.swift      # Codable models
│   │   ├── Network/
│   │   │   ├── APIError.swift
│   │   │   ├── APIEndpoint.swift
│   │   │   └── APIClient.swift      # actor: URLSession async/await
│   │   └── Repository/
│   │       └── CredentialRepository.swift
│   ├── Storage/
│   │   └── CredentialStore.swift
│   ├── Utils/
│   │   ├── AppLogger.swift
│   │   ├── Data+Base64URL.swift
│   │   └── Data+Hex.swift
│   └── UI/
│       ├── Theme/ (Colors, Typography)
│       ├── Components/ (SharedComponents, BiometricAuthHandler)
│       ├── Navigation/AppNavigation.swift
│       ├── Screens/ (HomeScreen, DIDScreen, RSAScreen)
│       └── ViewModels/
│           ├── BiometricAwareViewModel.swift
│           ├── DIDUIState.swift + DIDViewModel.swift
│           └── RSAUIState.swift + RSAViewModel.swift
└── DIDBlockchainlessDemoTests/
    ├── Base58Tests.swift
    ├── DataExtensionTests.swift
    └── JWTStructureTests.swift
```
