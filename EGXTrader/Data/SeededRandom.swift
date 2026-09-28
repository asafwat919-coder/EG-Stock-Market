import Foundation

/// Small, fast deterministic PRNG so simulated history is identical across launches.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform value in `0..<1`.
    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    mutating func uniform(_ lower: Double, _ upper: Double) -> Double {
        lower + (upper - lower) * unit()
    }

    /// Standard normal sample (Box-Muller).
    mutating func gaussian() -> Double {
        let u1 = max(unit(), .leastNonzeroMagnitude)
        let u2 = unit()
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }
}

enum StableHash {
    /// FNV-1a. Unlike `Hasher`, the result is stable across app launches.
    static func of(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    static func of(day: Date) -> UInt64 {
        of("day-\(Int(day.timeIntervalSince1970 / 86_400))")
    }
}
