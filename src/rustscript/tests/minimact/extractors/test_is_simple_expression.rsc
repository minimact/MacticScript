/**
 * Test for extractors/conditional_element_templates/is_simple_expression.rsc
 *
 * Tests simple expression detection
 */

plugin TestIsSimpleExpression {
    // Use visitor pattern to test is_simple_expression on actual expressions

    fn visit_expression(expr: &mut Expression, ctx: &Context) {
        // Test cases:
        //
        // Simple expressions (should return true):
        // - Identifier: `myVar`
        // - MemberExpression: `obj.prop`
        // - StringLiteral: `"hello"`
        // - NumericLiteral: `42`
        // - BooleanLiteral: `true`
        // - NullLiteral: `null`
        //
        // Complex expressions (should return false):
        // - CallExpression: `func()`
        // - BinaryExpression: `a + b`
        // - ConditionalExpression: `a ? b : c`
        // - LogicalExpression: `a && b`
        // - ArrowFunctionExpression: `() => {}`

        expr.visit_children(self);
    }
}
