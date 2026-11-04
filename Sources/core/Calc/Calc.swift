//
//  Calc.swift
//  SwhopCore
//
//  Created by Yesset Murat on 31.10.2026.
//

// The calculator: `+ - * /`, parentheses, decimals (`.` or `,`),
// unary minus and Alfred-style percent.

import Foundation

public enum Calc {

    /// The value of an arithmetic expression; nil unless all of it parses,
    /// it has an operator or `%` (a bare number is not a calculation), and
    /// the result is finite.
    public static func eval(_ input: String) -> Double? {
        let hasOp = { (s: String) in !s.filter({ "+-*/%".contains($0) }).isEmpty }
        guard hasOp(input) else {
            return nil
        }

        let s = input.filter { !$0.isWhitespace }
        // A bare number with an optional minus is not a calculation.
        let t = String(s.dropFirst(s.hasPrefix("-") ? 1 : 0))
        guard hasOp(t) else {
            return nil
        }

        var p = Parser(chars: Array(s), i: 0)
        guard let v = p.expr() else {
            return nil
        }
        return p.i == s.count && v.isFinite ? v : nil
    }

    /// At most 10 decimals, no trailing zeros.
    public static func format(_ x: Double) -> String {
        var s = String(format: "%.10f", x)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s == "-0" ? "0" : s
    }

    private struct Parser {

        let chars: [Character]
        var i = 0

        mutating func peek() -> Character? { chars.indices.contains(i) ? chars[i] : nil }

        @discardableResult
        mutating func eat(_ c: Character) -> Bool {
            if peek() == c { i += 1; return true }
            return false
        }

        /// `term (('+'|'-') term)*`; `a + b%` adds b percent of a.
        mutating func expr() -> Double? {
            guard var acc = term()?.value else {
                return nil
            }
            while true {
                let sign: Double
                if eat("+") { sign = 1 } else if eat("-") { sign = -1 } else { return acc }
                guard let t = term() else {
                    return nil
                }
                acc += sign * (t.pct.map { acc * $0 / 100.0 } ?? t.value)
            }
        }

        /// `factor (('*'|'/') factor)*`, and the percent if the term is just `x%`.
        mutating func term() -> (value: Double, pct: Double?)? {
            guard var f = factor() else {
                return nil
            }
            while true {
                if eat("*") {
                    guard let r = factor() else {
                        return nil
                    }
                    f.value *= r.value
                    f.pct = nil
                } else if eat("/") {
                    guard let r = factor() else {
                        return nil
                    }
                    f.value /= r.value
                    f.pct = nil
                } else {
                    return f
                }
            }
        }

        /// `'-' factor | primary '%'?`: the value (x% is x/100) and x if `%`.
        mutating func factor() -> (value: Double, pct: Double?)? {
            if eat("-") {
                guard let f = factor() else {
                    return nil
                }
                return (value: -f.value, pct: f.pct.map { -$0 })
            }
            guard let v = primary() else {
                return nil
            }
            if eat("%") { return (value: v / 100.0, pct: v) }
            return (value: v, pct: nil)
        }

        mutating func primary() -> Double? {
            if eat("(") {
                guard let v = expr(), eat(")") else {
                    return nil
                }
                return v
            }
            let start = i
            while let c = peek(), c.isNumber || c == "." || c == "," { i += 1 }
            let num = String(chars[start..<i].map { $0 == "," ? Character(".") : $0 })
            return Double(num)
        }
    }
}
