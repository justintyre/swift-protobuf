// Sources/SwiftProtobuf/ExtensionFields.swift - Extension support
//
// Copyright (c) 2014 - 2016 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Core protocols implemented by generated extensions.
///
// -----------------------------------------------------------------------------

//
// Type-erased Extension field implementation.
// Note that it has no "self or associated type" references, so can
// be used as a protocol type.  (In particular, although it does have
// a hashValue property, it cannot be Hashable.)
//
// This can encode, decode, return a hashValue and test for
// equality with some other extension field; but it's type-sealed
// so you can't actually access the contained value itself.
//
public protocol AnyExtensionField: Sendable {
  func hash(into hasher: inout Hasher)
  var protobufExtension: AnyMessageExtension { get }
  func isEqual(other: AnyExtensionField) -> Bool

  /// Merging field decoding
  mutating func decodeExtensionField<T: Decoder>(decoder: inout T) throws

  /// Fields know their own type, so can dispatch to a visitor
  func traverse<V: Visitor>(visitor: inout V) throws

  /// Check if the field is initialized.
  var isInitialized: Bool { get }
}

extension AnyExtensionField {
  // Default implementation for extensions fields.  The message types below provide
  // custom versions.
  public var isInitialized: Bool { return true }
}

///
/// The regular ExtensionField type exposes the value directly.
///
public protocol ExtensionField: AnyExtensionField, Hashable, Sendable {
  associatedtype ValueType
  var value: ValueType { get set }
  init(protobufExtension: AnyMessageExtension, value: ValueType)
  init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws
}

///
/// Singular field
///
public struct OptionalExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = BaseType
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalExtensionField,
                        rhs: OptionalExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalExtensionField<T>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
      var v: ValueType?
      try T.decodeSingular(value: &v, from: &decoder)
      if let v = v {
          value = v
      }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try T.decodeSingular(value: &v, from: &decoder)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try T.visitSingular(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
  }
}

#if DEBUG
extension OptionalExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    get {
      return String(reflecting: value)
    }
  }
}
#endif

///
/// Repeated fields
///
public struct RepeatedExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedExtensionField,
                        rhs: RepeatedExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedExtensionField<T>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try T.decodeRepeated(value: &value, from: &decoder)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try T.decodeRepeated(value: &v, from: &decoder)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try T.visitRepeated(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
  }
}

#if DEBUG
extension RepeatedExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }
}
#endif

///
/// Packed Repeated fields
///
/// TODO: This is almost (but not quite) identical to RepeatedFields;
/// find a way to collapse the implementations.
///
public struct PackedExtensionField<T: FieldType>: ExtensionField {
  public typealias BaseType = T.BaseType
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: PackedExtensionField,
                        rhs: PackedExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! PackedExtensionField<T>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try T.decodeRepeated(value: &value, from: &decoder)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try T.decodeRepeated(value: &v, from: &decoder)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try T.visitPacked(value: value, fieldNumber: protobufExtension.fieldNumber, with: &visitor)
    }
  }
}

#if DEBUG
extension PackedExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }
}
#endif

///
/// Enum extensions
///
public struct OptionalEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = E
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalEnumExtensionField,
                        rhs: OptionalEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalEnumExtensionField<E>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
      var v: ValueType?
      try decoder.decodeSingularEnumField(value: &v)
      if let v = v {
          value = v
      }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try decoder.decodeSingularEnumField(value: &v)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try visitor.visitSingularEnumField(
      value: value,
      fieldNumber: protobufExtension.fieldNumber)
  }
}

#if DEBUG
extension OptionalEnumExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    get {
      return String(reflecting: value)
    }
  }
}
#endif

///
/// Repeated Enum fields
///
public struct RepeatedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = [E]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedEnumExtensionField,
                        rhs: RepeatedEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedEnumExtensionField<E>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedEnumField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedEnumField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedEnumField(
        value: value,
        fieldNumber: protobufExtension.fieldNumber)
    }
  }
}

#if DEBUG
extension RepeatedEnumExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }
}
#endif

///
/// Packed Repeated Enum fields
///
/// TODO: This is almost (but not quite) identical to RepeatedEnumFields;
/// find a way to collapse the implementations.
///
public struct PackedEnumExtensionField<E: Enum>: ExtensionField where E.RawValue == Int {
  public typealias BaseType = E
  public typealias ValueType = [E]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: PackedEnumExtensionField,
                        rhs: PackedEnumExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! PackedEnumExtensionField<E>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedEnumField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedEnumField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitPackedEnumField(
        value: value,
        fieldNumber: protobufExtension.fieldNumber)
    }
  }
}

#if DEBUG
extension PackedEnumExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }
}
#endif

//
// ========== Message ==========
//
public struct OptionalMessageExtensionField<M: Message & Equatable>:
  ExtensionField {
  public typealias BaseType = M
  public typealias ValueType = BaseType
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalMessageExtensionField,
                        rhs: OptionalMessageExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    value.hash(into: &hasher)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalMessageExtensionField<M>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    var v: ValueType? = value
    try decoder.decodeSingularMessageField(value: &v)
    if let v = v {
      self.value = v
    }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try decoder.decodeSingularMessageField(value: &v)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try visitor.visitSingularMessageField(
      value: value, fieldNumber: protobufExtension.fieldNumber)
  }

  public var isInitialized: Bool {
    return value.isInitialized
  }
}

#if DEBUG
extension OptionalMessageExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    get {
      return String(reflecting: value)
    }
  }
}
#endif

public struct RepeatedMessageExtensionField<M: Message & Equatable>:
  ExtensionField {
  public typealias BaseType = M
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedMessageExtensionField,
                        rhs: RepeatedMessageExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    for e in value {
      e.hash(into: &hasher)
    }
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedMessageExtensionField<M>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedMessageField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedMessageField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedMessageField(
        value: value, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    return Internal.areAllInitialized(value)
  }
}

#if DEBUG
extension RepeatedMessageExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "[" + value.map{String(reflecting: $0)}.joined(separator: ",") + "]"
  }
}
#endif

//
// ======== Groups within Messages ========
//
// Protoc internally treats groups the same as messages, but
// they serialize very differently, so we have separate serialization
// handling here...
public struct OptionalGroupExtensionField<G: Message & Hashable>:
  ExtensionField {
  public typealias BaseType = G
  public typealias ValueType = BaseType
  public var value: G
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: OptionalGroupExtensionField,
                        rhs: OptionalGroupExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! OptionalGroupExtensionField<G>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    var v: ValueType? = value
    try decoder.decodeSingularGroupField(value: &v)
    if let v = v {
      value = v
    }
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType?
    try decoder.decodeSingularGroupField(value: &v)
    if let v = v {
      self.init(protobufExtension: protobufExtension, value: v)
    } else {
      return nil
    }
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    try visitor.visitSingularGroupField(
      value: value, fieldNumber: protobufExtension.fieldNumber)
  }

  public var isInitialized: Bool {
    return value.isInitialized
  }
}

#if DEBUG
extension OptionalGroupExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    get {
      return value.debugDescription
    }
  }
}
#endif

public struct RepeatedGroupExtensionField<G: Message & Hashable>:
  ExtensionField {
  public typealias BaseType = G
  public typealias ValueType = [BaseType]
  public var value: ValueType
  public var protobufExtension: AnyMessageExtension

  public static func ==(lhs: RepeatedGroupExtensionField,
                        rhs: RepeatedGroupExtensionField) -> Bool {
    return lhs.value == rhs.value
  }

  public init(protobufExtension: AnyMessageExtension, value: ValueType) {
    self.protobufExtension = protobufExtension
    self.value = value
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }

  public func isEqual(other: AnyExtensionField) -> Bool {
    let o = other as! RepeatedGroupExtensionField<G>
    return self == o
  }

  public mutating func decodeExtensionField<D: Decoder>(decoder: inout D) throws {
    try decoder.decodeRepeatedGroupField(value: &value)
  }

  public init?<D: Decoder>(protobufExtension: AnyMessageExtension, decoder: inout D) throws {
    var v: ValueType = []
    try decoder.decodeRepeatedGroupField(value: &v)
    self.init(protobufExtension: protobufExtension, value: v)
  }

  public func traverse<V: Visitor>(visitor: inout V) throws {
    if value.count > 0 {
      try visitor.visitRepeatedGroupField(
        value: value, fieldNumber: protobufExtension.fieldNumber)
    }
  }

  public var isInitialized: Bool {
    return Internal.areAllInitialized(value)
  }
}

#if DEBUG
extension RepeatedGroupExtensionField: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "[" + value.map{$0.debugDescription}.joined(separator: ",") + "]"
  }
}
#endif
