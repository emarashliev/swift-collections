//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Loosely adapted from https://github.com/apple/swift/tree/main/stdlib/private/StdlibCollectionUnittest

// FIXME: Port all of the collection validation tests from the Swift compiler codebase.

import XCTest

extension BidirectionalCollection {
  func _indicesByIndexBefore() -> [Index] {
    var result: [Index] = []
    var i = endIndex
    while i != startIndex {
      i = index(before: i)
      result.append(i)
    }
    result.reverse()
    return result
  }

  func _indicesByFormIndexBefore() -> [Index] {
    var result: [Index] = []
    var i = endIndex
    while i != startIndex {
      formIndex(before: &i)
      result.append(i)
    }
    result.reverse()
    return result
  }
}

public func checkBidirectionalCollection<C: BidirectionalCollection, S: Sequence>(
  _ collection: C,
  expectedContents: S,
  maxSamples: Int? = nil,
  file: StaticString = #file,
  line: UInt = #line
) where C.Element: Equatable, S.Element == C.Element {
  checkBidirectionalCollection(
    collection,
    expectedContents: expectedContents,
    by: ==,
    maxSamples: maxSamples,
    file: file,
    line: line)
}

public func checkBidirectionalCollection<C: BidirectionalCollection, S: Sequence>(
  _ collection: C,
  expectedContents: S,
  by areEquivalent: (S.Element, S.Element) -> Bool,
  maxSamples: Int? = nil,
  file: StaticString = #file,
  line: UInt = #line
) where S.Element == C.Element {
  checkSequence(
    { collection }, expectedContents: expectedContents,
    by: areEquivalent,
    file: file, line: line)
  _checkCollection(
    collection, expectedContents: expectedContents,
    by: areEquivalent,
    maxSamples: maxSamples,
    file: file, line: line)
  _checkBidirectionalCollection(
    collection, expectedContents: expectedContents,
    by: areEquivalent,
    maxSamples: maxSamples,
    file: file, line: line)
}

public func _checkBidirectionalCollection<C: BidirectionalCollection, S: Sequence>(
  _ collection: C,
  expectedContents: S,
  by areEquivalent: (S.Element, S.Element) -> Bool,
  maxSamples: Int? = nil,
  file: StaticString = #file,
  line: UInt = #line
) where S.Element == C.Element {
  let entry = TestContext.current.push("checkBidirectionalCollection", file: file, line: line)
  defer { TestContext.current.pop(entry) }

  let expectedContents = Array(expectedContents)

  // Check that `index(before:)` and `formIndex(before:)` are consistent with `index(after:)`.
  let indicesByIndexAfter = collection._indicesByIndexAfter()
  let indicesByIndexBefore = collection._indicesByIndexBefore()
  let indicesByFormIndexBefore = collection._indicesByFormIndexBefore()
  expectEqual(indicesByIndexBefore, indicesByIndexAfter)
  expectEqual(indicesByFormIndexBefore, indicesByIndexAfter)

  // Check contents using indexing.
  let indexContents1 = indicesByIndexBefore.map { collection[$0] }
  expectEquivalentElements(
    indexContents1, expectedContents,
    by: areEquivalent,
    "\(expectedContents)")
  let indexContents2 = indicesByFormIndexBefore.map { collection[$0] }
  expectEquivalentElements(
    indexContents2, expectedContents,
    by: areEquivalent,
    "\(expectedContents)")

  // Check the Indices associated type
  if C.self != C.Indices.self {
    checkBidirectionalCollection(
      collection.indices,
      expectedContents: indicesByIndexAfter,
      maxSamples: maxSamples)
  }

  var allIndices = indicesByIndexAfter
  allIndices.append(collection.endIndex)

  withSomeRanges(
    "range",
    in: 0 ..< allIndices.count - 1,
    maxSamples: maxSamples
  ) { range in
    let i = range.lowerBound
    let j = range.upperBound

    // Check `index(_,offsetBy:)` with negative offsets
    let a = collection.index(allIndices[j], offsetBy: i - j)
    expectEqual(a, allIndices[i])
    if i < expectedContents.count {
      expectEquivalent(
        collection[a], expectedContents[i],
        by: areEquivalent)
    }

    // Check `distance(from:to:)` with decreasing indices
    let d = collection.distance(from: allIndices[j], to: allIndices[i])
    expectEqual(d, i - j)

    // Check slicing.
    let slice = collection[allIndices[i] ..< allIndices[j]]
    expectEqualElements(slice._indicesByIndexBefore(), allIndices[i ..< j])
    expectEqualElements(slice._indicesByFormIndexBefore(), allIndices[i ..< j])
  }
}
