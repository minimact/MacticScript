# RustScript Minimact Testing Strategy

## Philosophy

RustScript is a **DSL for writing AST transformation plugins**, not a general-purpose programming language. This fundamental design constraint shapes how we should test RustScript code.

## ❌ Anti-Pattern: Mock AST Node Construction

**Don't do this:**
```rustscript
// ❌ BAD: Trying to manually construct AST nodes
plugin TestStyleConverter {
    fn test_convert_style_value() {
        let expr = NumericLiteral { value: 12.0 };  // Error: NumericLiteral not defined
        let result = convert_style_value(&expr);
    }
}
```

**Why this doesn't work:**
- RustScript doesn't define all Babel/SWC AST node types as constructable structs
- Adding them would be a massive undertaking and goes against the minimal DSL philosophy
- This is trying to use RustScript as a unit testing framework, which it's not designed for

## ✅ Correct Pattern: Integration Tests with Visitors

**Do this instead:**
```rustscript
// ✅ GOOD: Using visitor pattern to test helpers
plugin TestStyleConverter {
    fn visit_jsx_attribute(&mut self, attr: &mut JSXAttribute, ctx: &Context) {
        if attr.name == "style" {
            // Test style conversion helpers by transforming real JSX
            let css = convert_style_object_to_css(&attr.value);
        }
    }
}
```

**Or test pure functions:**
```rustscript
// ✅ GOOD: Testing pure string/value functions
plugin TestHelpers {
    fn test_string_functions() {
        let result1 = camel_to_kebab("marginTop");
        // result1 should be "margin-top"

        let result2 = escape_csharp_string("Hello\nWorld");
        // result2 should be "Hello\\nWorld"
    }
}
```

## Testing Approaches by Function Type

### 1. Pure Utility Functions (String, Math, etc.)

**Functions like:** `escape_csharp_string()`, `camel_to_kebab()`, `format()`, etc.

**Test approach:** Direct function calls with literal values

**Example:**
```rustscript
plugin TestUtilities {
    fn test_string_helpers() {
        let escaped = escape_csharp_string("test\"quote");
        let kebab = camel_to_kebab("myVariable");
        let formatted = format!("Hello {}", "World");
    }
}
```

### 2. AST Analysis Functions (Extraction, Detection, etc.)

**Functions like:** `is_component_name()`, `get_hook_type()`, `extract_prop_name()`, etc.

**Test approach:** Use visitor pattern on real code

**Example:**
```rustscript
plugin TestAnalyzers {
    fn visit_function_declaration(&mut self, node: &mut FunctionDeclaration, ctx: &Context) {
        // Test component detection
        if let Some(name) = get_component_name(node) {
            let is_comp = is_component_name(&name);
            // Verify behavior by transforming based on result
        }
    }
}
```

### 3. AST Transformation Functions (Converters, Generators, etc.)

**Functions like:** `convert_style_object_to_css()`, `generate_csharp_field()`, etc.

**Test approach:** Integration tests that transform actual code

**Example:**
```rustscript
plugin TestTransformers {
    fn visit_jsx_element(&mut self, elem: &mut JSXElement, ctx: &Context) {
        // Test by transforming real JSX elements
        for attr in &mut elem.opening_element.attributes {
            if attr.name == "style" {
                // Apply transformation helpers
                let css = convert_style_object_to_css(&attr.value);
            }
        }
    }
}
```

### 4. Complex Multi-Step Functions

**Functions like:** `extract_conditional_template()`, `analyze_dependencies()`, etc.

**Test approach:** End-to-end integration tests or move to JavaScript unit tests

**Example:**

**Option A - RustScript Integration Test:**
```rustscript
plugin TestExtractors {
    fn visit_conditional_expression(&mut self, cond: &mut ConditionalExpression, ctx: &Context) {
        // Test extraction by visiting actual conditional expressions
        let template = extract_ternary_element_template(cond);
    }
}
```

**Option B - JavaScript Unit Test (Recommended for complex logic):**
```javascript
// tests/unit/extractors.test.js
const { extract_ternary_element_template } = require('./extractors');

describe('extract_ternary_element_template', () => {
    it('should extract template from ternary JSX', () => {
        const ast = parse('const x = condition ? <div/> : <span/>');
        const result = extract_ternary_element_template(ast);
        expect(result).toEqual({ /* ... */ });
    });
});
```

## Test Organization

### RustScript Tests (`tests/minimact/*.rsc`)

**Purpose:** Verify compilation and basic functionality
**Scope:**
- Pure utility functions
- Integration tests with visitor pattern
- Smoke tests for complex functions

**Example structure:**
```
tests/minimact/
├── utils/
│   ├── test_helpers.rsc              # Pure utility functions
│   ├── test_hex_path.rsc             # Data structure helpers
│   └── test_style_converter_integration.rsc  # Integration test
├── types/
│   └── test_type_conversion_integration.rsc
└── analyzers/
    └── test_detection_integration.rsc
```

### JavaScript/TypeScript Unit Tests (Recommended for complex logic)

**Purpose:** Detailed unit testing with mock AST nodes
**Scope:**
- Complex extraction functions
- Multi-step transformations
- Edge cases and error handling

**Example structure:**
```
babel-plugin-minimact/tests/
├── unit/
│   ├── extractors.test.js
│   ├── analyzers.test.js
│   └── generators.test.js
└── integration/
    └── full-transform.test.js
```

## Testing Workflow

### For New RustScript Modules

1. **Write the RustScript module**
   ```
   rustscript-plugin-minimact/utils/my_helper.rsc
   ```

2. **Create RustScript compilation test**
   ```
   tests/minimact/utils/test_my_helper.rsc
   ```
   - Test pure functions directly
   - Test AST functions with visitor pattern
   - Keep tests simple - just verify compilation and basic behavior

3. **Add to test runner**
   ```python
   # test_minimact.py
   test_modules = {
       "utils": [
           "tests/minimact/utils/test_my_helper.rsc",
       ],
   }
   ```

4. **Run tests**
   ```bash
   cd src/rustscript
   python test_minimact.py
   ```

5. **(Optional) Add detailed JavaScript unit tests**
   - For complex logic
   - For edge cases
   - For error handling

## Current Test Coverage

### ✅ Passing Tests

1. **test_helpers.rsc**
   - Tests: `escape_csharp_string()`, `get_component_name()`, `is_component_name()`
   - Approach: Direct function calls
   - Status: ✅ All passing

2. **test_hex_path.rsc**
   - Tests: `HexPathGenerator` and all its methods
   - Approach: Direct method calls on struct
   - Status: ✅ All passing

3. **test_style_converter_integration.rsc**
   - Tests: `camel_to_kebab()`
   - Approach: Direct function calls
   - Status: ✅ All passing

4. **test_type_conversion_integration.rsc**
   - Tests: Visitor pattern integration
   - Approach: Visitor pattern (placeholder for now)
   - Status: ✅ Compiles successfully

### 📝 Tests to Add

- [ ] Analyzer modules (detection, classification, dependencies)
- [ ] Extractor modules (props, hooks, conditionals, loops)
- [ ] Generator modules (C# code generation)
- [ ] More detailed integration tests

## Benefits of This Approach

### ✅ Advantages

1. **Aligns with RustScript's design** - Uses the language as intended
2. **Tests real compilation** - Verifies generated Babel and SWC code
3. **Catches codegen bugs** - String escaping, syntax errors, etc.
4. **Maintainable** - Simple, focused tests
5. **Fast** - Compilation tests are quick

### ✅ What We Verify

- RustScript module compiles to both Babel and SWC
- Generated JavaScript is syntactically valid
- Generated Rust is syntactically valid
- Basic functionality of pure functions
- Integration with visitor pattern

### ⚠️ What We Don't Verify (Use JavaScript tests for this)

- Detailed edge cases
- Complex AST manipulation scenarios
- Error handling paths
- Runtime behavior with mock data

## Conclusion

**RustScript tests should focus on:**
1. ✅ Compilation verification
2. ✅ Pure function testing
3. ✅ Integration with visitor pattern
4. ✅ Smoke tests for complex functions

**JavaScript/TypeScript unit tests should handle:**
1. ✅ Detailed unit testing with mocks
2. ✅ Edge cases and error paths
3. ✅ Complex AST manipulation scenarios

This hybrid approach plays to each tool's strengths and provides comprehensive test coverage.
