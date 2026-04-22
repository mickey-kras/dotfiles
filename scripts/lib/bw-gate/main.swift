// bw-gate-helper — Touch ID / password-gated Bitwarden session-token storage
// for macOS.
//
// Current approach: LAContext gate + regular keychain item.
//
// This is intentionally the simpler "Path B" design:
//   1. Storage: a regular generic-password keychain item.
//   2. Gate: LocalAuthentication prompts on every read.
//
// That means this helper provides a convenient local auth gate for a
// short-lived Bitwarden session token, but it is not yet using item-level
// biometric ACLs such as `.biometryCurrentSet`.

import Foundation
import LocalAuthentication
import Security

let kService = "bw-gate"
let kAccount = "session-token"

func die(_ msg: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("bw-gate-helper: \(msg)\n".utf8))
    exit(code)
}

func baseQuery() -> [String: Any] {
    return [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: kService,
        kSecAttrAccount as String: kAccount,
    ]
}

func cmdHas() -> Never {
    var query = baseQuery()
    query[kSecReturnAttributes as String] = true
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    switch status {
    case errSecSuccess:
        exit(0)
    case errSecItemNotFound:
        exit(1)
    default:
        die("has: unexpected status \(status)")
    }
}

func cmdGet() -> Never {
    let context = LAContext()
    var error: NSError?
    let policy: LAPolicy

    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        policy = .deviceOwnerAuthentication
    } else {
        policy = .deviceOwnerAuthentication
    }

    let semaphore = DispatchSemaphore(value: 0)
    var authOK = false
    var authError: Error?

    context.evaluatePolicy(
        policy,
        localizedReason: "Use Touch ID or your Mac password to unlock the cached Bitwarden session token for your AI tools"
    ) { success, err in
        authOK = success
        authError = err
        semaphore.signal()
    }
    semaphore.wait()

    guard authOK else {
        if let laError = authError as? LAError, laError.code == .userCancel {
            die("get: authentication cancelled", code: 2)
        }
        die(
            "get: authentication failed: \(authError?.localizedDescription ?? "unknown")",
            code: 2
        )
    }

    var query = baseQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    switch status {
    case errSecSuccess:
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            die("get: keychain returned non-utf8 data")
        }
        FileHandle.standardOutput.write(Data(token.utf8))
        exit(0)
    case errSecItemNotFound:
        die("get: no token stored (run: bw-gate unlock)", code: 1)
    case errSecUserCanceled, errSecAuthFailed:
        die("get: authentication cancelled or failed", code: 2)
    default:
        die("get: unexpected status \(status)")
    }
}

func cmdSet() -> Never {
    let token = FileHandle.standardInput.readDataToEndOfFile()
    var bytes = [UInt8](token)
    while let last = bytes.last, last == 0x0A || last == 0x0D {
        bytes.removeLast()
    }

    if bytes.isEmpty {
        die("set: no token on stdin")
    }

    let data = Data(bytes)
    SecItemDelete(baseQuery() as CFDictionary)

    var query = baseQuery()
    query[kSecValueData as String] = data

    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess {
        die("set: SecItemAdd failed (status \(status))")
    }
    exit(0)
}

func cmdClear() -> Never {
    let status = SecItemDelete(baseQuery() as CFDictionary)
    switch status {
    case errSecSuccess, errSecItemNotFound:
        exit(0)
    default:
        die("clear: unexpected status \(status)")
    }
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write(Data("usage: bw-gate-helper {set|get|has|clear}\n".utf8))
    exit(64)
}

switch args[1] {
case "set":
    cmdSet()
case "get":
    cmdGet()
case "has":
    cmdHas()
case "clear":
    cmdClear()
case "-h", "--help":
    print("""
    bw-gate-helper — Touch ID / password-gated Bitwarden session-token storage

    usage:
      printf %s "$token" | bw-gate-helper set    store a token
      bw-gate-helper get                         retrieve token
      bw-gate-helper has                         check presence without prompting
      bw-gate-helper clear                       delete the token

    keychain: service=\(kService), account=\(kAccount)
    """)
    exit(0)
default:
    die("unknown subcommand: \(args[1]) (try --help)", code: 64)
}
