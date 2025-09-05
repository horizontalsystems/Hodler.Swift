import BitcoinCore
import Foundation

public protocol IHodlerAddressConverter {
    func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address
}

public protocol IHodlerPublicKeyStorage {
    func publicKey(hashP2pkh hash: Data) -> PublicKey?
}

public protocol IHodlerBlockMedianTimeHelper {
    var medianTimePast: Int? { get }
}
