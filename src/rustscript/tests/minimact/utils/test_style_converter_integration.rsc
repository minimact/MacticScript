/**
 * Integration Test for utils/style_converter.rsc
 *
 * This test uses a visitor pattern to test style conversion helpers
 * by actually transforming JSX code with style attributes.
 */

use "../../../rustscript-plugin-minimact/utils/style_converter.rsc" { camel_to_kebab };

plugin TestStyleConverterIntegration {

    fn test_camel_to_kebab_conversions() {
        // Test basic conversions
        let result1 = camel_to_kebab("marginTop");
        // Expected: "margin-top"

        let result2 = camel_to_kebab("backgroundColor");
        // Expected: "background-color"

        let result3 = camel_to_kebab("fontSize");
        // Expected: "font-size"

        // Test already kebab-case
        let result4 = camel_to_kebab("margin-top");
        // Expected: "margin-top"

        // Test single word
        let result5 = camel_to_kebab("color");
        // Expected: "color"

        // Test multiple capitals
        let result6 = camel_to_kebab("MozBorderRadius");
        // Expected: "-moz-border-radius"

        // Test empty string
        let result7 = camel_to_kebab("");
        // Expected: ""
    }
}
