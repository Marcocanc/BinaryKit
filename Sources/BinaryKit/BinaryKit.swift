import Foundation

enum BinError: Error {
    case outOfBounds
    case notString
}

struct Binary {
    private var bitCursor: Int
    var bytesStore: [UInt8]
    private let byteSize = 8
    
    init(bytes: [UInt8]) {
        self.bitCursor = 0
        self.bytesStore = bytes
    }
    
    /// Initialize with a `String` of hexadecimal values.
    init?(hexString: String) {
        let bytes = hexString.chunked(by: 2).compactMap{ UInt8($0, radix: 16) }
        guard hexString.count == bytes.count * 2 else {
            return nil
        }
        self.init(bytes: bytes)
    }
    
    // MARK: - Cursor
    
    /// Returns an `Int` with the value of `bitCursor` incremented by `bits`.
    private func incrementedCursorBy(bits: Int) -> Int {
        return bitCursor + bits
    }
    
    /// Returns an `Int` with the value of `bitCursor` incremented by `bytes`.
    private func incrementedCursorBy(bytes: Int) -> Int {
        return bitCursor + (bytes * byteSize)
    }
    
    /// Sets the reading cursor back to its initial value.
    mutating func resetCursor() {
        self.bitCursor = 0
    }
    
    // MARK: - Bit
    
    /// Returns the binary value `0` or `1` of the given position.
    func getBit(index: Int) throws -> UInt8 {
        guard (0..<(bytesStore.count)).contains(index / byteSize) else {
            throw BinError.outOfBounds
        }
        let byteCursor = index / byteSize
        let bitindex = 7 - (index % byteSize)
        return (bytesStore[byteCursor] >> bitindex) & 1
    }
    
    /// Returns the `Int`-value of the given range.
    mutating func getBits(range: Range<Int>) throws -> Int {
        guard (0...(bytesStore.count * byteSize)).contains(range.endIndex) else {
            throw BinError.outOfBounds
        }
        return try range.reversed().enumerated().reduce(0) {
            $0 + Int(try getBit(index: $1.element) << $1.offset)
        }
    }
    
    /// Returns the binary value `0` or `1` of the given position and
    /// increments the reading cursor by one bit.
    mutating func readBit() throws -> UInt8 {
        defer { bitCursor = incrementedCursorBy(bits: 1) }
        return try getBit(index: bitCursor)
    }
    
    /// Returns the `Int`-value of the next n-bits (`quantitiy`)
    /// and increments the reading cursor by n-bits.
    mutating func readBits(quantitiy: Int) throws -> Int {
        guard (0...(bytesStore.count * byteSize)).contains(bitCursor + quantitiy) else {
            throw BinError.outOfBounds
        }
        defer { bitCursor = incrementedCursorBy(bits: quantitiy) }
        return try (bitCursor..<(bitCursor + quantitiy)).reversed().enumerated().reduce(0) {
            $0 + Int(try getBit(index: $1.element) << $1.offset)
        }
    }
    
    // MARK: - Byte
    
    /// Returns the `UInt8`-value of the given `index`.
    func getByte(index: Int) throws -> UInt8 {
        /// Check if `index` is within bounds of `bytes`
        guard (0..<(bytesStore.count)).contains(index) else {
            throw BinError.outOfBounds
        }
        return bytesStore[index]
    }
    
    /// Returns an `[UInt8]` of the given `range`.
    func getBytes(range: Range<Int>) throws -> [UInt8] {
        guard (0...(bytesStore.count)).contains(range.endIndex) else {
            throw BinError.outOfBounds
        }
        return Array(bytesStore[range])
    }
    
    /// Returns the `UInt8`-value of the next byte and increments the reading cursor.
    mutating func readByte() throws -> UInt8 {
        let result = try getByte(index: bitCursor / byteSize)
        bitCursor = incrementedCursorBy(bytes: 1)
        return result
    }
    
    /// Returns an `[UInt8]` of the next n-bytes (`quantitiy`) and
    /// increments the reading cursor by n-bytes.
    mutating func readBytes(quantitiy: Int) throws -> [UInt8] {
        let byteCursor = bitCursor / byteSize
        defer { bitCursor = incrementedCursorBy(bytes: quantitiy) }
        return try getBytes(range: byteCursor..<(byteCursor + quantitiy))
    }
    
    // MARK: - String
    
    mutating func readString(quantitiyOfBytes quantitiy: Int, encoding: String.Encoding = .utf8) throws -> String {
        guard let result = String(bytes: try self.readBytes(quantitiy: quantitiy), encoding: encoding) else {
            throw BinError.notString
        }
        return result
    }
    
    mutating func getCharacter() throws -> Character {
        return Character(UnicodeScalar(try readByte()))
    }
    
    mutating func readBool() throws -> Bool {
        return try readBit() == 1
    }
}
