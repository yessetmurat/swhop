//
//  CalcTests.swift
//  SwhopCoreTests
//
//  Created by Yesset Murat on 04.11.2026.
//

import Testing
@testable import SwhopCore

@Test(arguments: [
    ("2+2*3", "8"), ("(2+2)*3", "12"), ("-3+5", "2"), ("7/2", "3.5"),
    ("1,5*2", "3"), ("200 + 10%", "220"), ("200 - 10%", "180"),
    ("200 * 10%", "20"), ("50%", "0.5"), ("-50%", "-0.5"), ("-5+1", "-4"),
])
func calcEvaluates(expression: String, want: String) {
    #expect(Calc.eval(expression).map(Calc.format) == want)
}

@Test(arguments: ["2+", "abc", "12", "1/0", "", "(1", "2 3", "-5", "-.5"])
func calcRejects(expression: String) {
    #expect(Calc.eval(expression) == nil)
}

@Test(arguments: [
    (3.5, "3.5"), (8.0, "8"), (0.1 + 0.2, "0.3"), (-0.0, "0"),
    (1.0 / 3.0, "0.3333333333"), (-2.5, "-2.5"),
])
func calcFormats(value: Double, want: String) {
    #expect(Calc.format(value) == want)
}
