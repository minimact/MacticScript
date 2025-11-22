/**
 * Test for analyzers/detection.rsc
 *
 * Tests pattern detection in JSX code
 */

plugin TestDetection {
    // These tests use the visitor pattern to test detection functions
    // on real JSX code

    fn visit_jsx_element(elem: &mut JSXElement, ctx: &Context) {
        // Test 1: Check for spread props
        // Input JSX: <div {...props} />
        // has_spread_props(&elem.opening_element.attributes) should return true

        // Test 2: No spread props
        // Input JSX: <div className="test" />
        // has_spread_props(&elem.opening_element.attributes) should return false

        // Test 3: Dynamic children with map
        // Input JSX: <div>{items.map(i => <span>{i}</span>)}</div>
        // has_dynamic_children(&elem.children) should return true

        // Test 4: Static children
        // Input JSX: <div>Hello World</div>
        // has_dynamic_children(&elem.children) should return false

        elem.visit_children(self);
    }

    fn visit_jsx_expression_container(container: &mut JSXExpressionContainer, ctx: &Context) {
        // Test 5: Conditional with JSX
        // Input: {condition ? <A/> : <B/>}
        // Should be detected as dynamic

        // Test 6: Logical expression with JSX
        // Input: {condition && <Element/>}
        // Should be detected as dynamic

        container.visit_children(self);
    }
}
