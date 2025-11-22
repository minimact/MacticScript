/**
 * Test for generators/expressions/calls/handle_string_methods.rsc
 *
 * Tests JavaScript to C# string method conversion
 */

plugin TestStringMethods {
    // Use visitor pattern to test string method transformations

    fn visit_call_expression(call: &mut CallExpression, ctx: &Context) {
        // Test cases for string method conversion:
        //
        // toFixed:
        // Input:  price.toFixed(2)
        // Output: price.ToString("F2")
        //
        // Input:  value.toFixed(4)
        // Output: value.ToString("F4")
        //
        // Input:  (a + b).toFixed(3)
        // Output: (a + b).ToString("F3")
        //
        // toLowerCase:
        // Input:  text.toLowerCase()
        // Output: text.ToLower()
        //
        // toUpperCase:
        // Input:  text.toUpperCase()
        // Output: text.ToUpper()
        //
        // substring:
        // Input:  str.substring(0, 5)
        // Output: str.Substring(0, 5)
        //
        // trim:
        // Input:  text.trim()
        // Output: text.Trim()

        call.visit_children(self);
    }
}
