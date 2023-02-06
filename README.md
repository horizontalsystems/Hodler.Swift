# Hodler.Swift

`Hodler.Swift` is a plugin to `BitcoinCore`, that makes it possible to lock bitcoins until some time in the future. It relies on [CHECKSEQUENCEVERIFY](https://github.com/bitcoin/bips/blob/master/bip-0112.mediawiki) and [Relative time-locks](https://github.com/bitcoin/bips/blob/master/bip-0068.mediawiki). It may be used with other forks of Bitcoin that support them. `UnstooppableWallet` opts in this plugin and enables it for Bitcoin as an experimental feature.

## How it works

To lock funds we create P2SH output where redeem script has `OP_CSV` OpCode that ensures that the input has a proper Sequence Number(`nSequence`) field and that it enables a relative time-lock. 

In [this](https://blockstream.info/tx/1cd11e80d04c82d098f19badb153ea12ec84cda408daaadc566cc129f967a435?input:1&expand) sample transaction the second input unlocks such an output. It has a signature, public key and the following redeem script in it's scriptSig:

`OP_PUSHBYTES_3 070040 OP_CSV OP_DROP OP_DUP OP_HASH160 OP_PUSHBYTES_20 853316620ed93e4ade18f8218f9aa15dc36c768e OP_EQUALVERIFY OP_CHECKSIG`

- `OP_PUSHBYTES_3 070040 OP_CSV OP_DROP` part ensures that needed amount of time is passed. Specifically `07` part of `070040` bytes says that it's locked for 1 hour. See [here](https://github.com/horizontalsystems/Hodler.Swift/blob/master/Sources/Hodler/Classes/Core/HodlerPlugin.swift#L16) and [here](https://github.com/bitcoin/bips/blob/master/bip-0068.mediawiki) for how it's evaluated.
- `OP_DUP OP_HASH160 OP_PUSHBYTES_20 853316620ed93e4ade18f8218f9aa15dc36c768e OP_EQUALVERIFY OP_CHECKSIG` part is the same locking script as of `P2PKH` output, that ensures the spender is the owner of the private key matching the public key hashed to `853316620ed93e4ade18f8218f9aa15dc36c768e`.

### Detection of incoming time-locked funds

When you have such an `P2SH` output, you only have an address and a hash of a redeem script in the output. If you are not aware of incoming time-locked funds in advance, there's no way you can detect that a particular output is yours. For this reason, we add an extra `OP_RETURN` output beside that `P2SH` output as a hint. That output tells us 

- ID of the plugin (1 byte): `BitcoinCore.Swift` can handle multiple plugins like this one.
- Time-lock period (2 bytes)
- Hash of the receiver's public key (20 bytes)

For example, [this](https://blockstream.info/tx/bdc3e995100269c8813f291dd9ea5489d8a17bd163002f70b5abbe05b5dccbd3?expand) is a *hint* output for the input above. It has following data:

`OP_RETURN OP_PUSHNUM_1 OP_PUSHBYTES_2 0700 OP_PUSHBYTES_20 853316620ed93e4ade18f8218f9aa15dc36c768e` 


## Limitations

### Locked time periods

This plugin can lock coins for `1 hour`, `1 month`, `half a year` and `1 year`. This is a limitation arising from the need of restoring those outputs using Simplified Payment Verification (SPV) `Bloom Filters`. Since each lock time generates different `P2SH` addresses, it wouldn't be possible to restore those outputs without knowing the exact lock time period in advance. So we generate 4 different addresses for each public key and use them in the bloom filters.

## Prerequisites

* Xcode 10.0+
* Swift 5+
* iOS 13+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/Hodler.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## License

The `Hodler` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/Hodler.Swift/blob/master/LICENSE).
