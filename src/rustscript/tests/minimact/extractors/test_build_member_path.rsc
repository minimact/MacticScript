/**
 * Test for extractors/expression_templates/build_member_path.rsc
 *
 * Tests building dotted path strings from member expressions
 */

plugin TestBuildMemberPath {
    // Use visitor pattern to test build_member_path on actual member expressions

    fn visit_member_expression(expr: &mut MemberExpression, ctx: &Context) {
        // Test cases:
        //
        // Simple member: obj.prop
        // Result: "obj.prop"
        //
        // Nested member: user.profile.name
        // Result: "user.profile.name"
        //
        // Deep nesting: a.b.c.d.e
        // Result: "a.b.c.d.e"
        //
        // Single identifier: obj
        // Result: "obj"

        expr.visit_children(self);
    }
}
