# Minimact RustScript Conversion Tests

This directory contains tests for verifying the correctness of the babel-plugin-minimact to RustScript conversion.

## Test Structure

```
tests/minimact/
├── utils/
│   ├── test_helpers.rsc           # Tests for utils/helpers.rsc
│   ├── test_hex_path.rsc          # Tests for utils/hex_path.rsc
│   └── test_style_converter.rsc   # Tests for utils/style_converter.rsc
├── types/
│   └── test_type_conversion.rsc   # Tests for types/type_conversion.rsc
├── analyzers/
│   └── (future analyzer tests)
├── extractors/
│   └── (future extractor tests)
└── README.md                      # This file
```

## Running Tests

### Run all minimact tests

```bash
cd src/rustscript
python test_minimact.py
```

### Run a specific test file

To compile and check a specific test:

```bash
cd src/rustscript
cargo run -- build tests/minimact/utils/test_helpers.rsc -o dist_test
```

## What the Tests Verify

Each test file verifies:

1. **Compilation Success** - The RustScript file compiles without errors to both Babel and SWC
2. **Syntax Validity** - Generated JavaScript and Rust code is syntactically valid
3. **Functionality** - Test functions exercise the converted helper functions with various inputs

## Test Coverage

### ✅ utils/helpers.rsc
- `escape_csharp_string()` - String escaping for C# output
- `get_component_name()` - Component name extraction
- `is_component_name()` - Component name validation

### ✅ utils/hex_path.rsc
- `HexPathGenerator::new()` - Generator creation
- `next()` - Path generation
- `build_path()` - Path building
- `parse_path()` - Path parsing
- `get_depth()` - Depth calculation
- `get_parent_path()` - Parent path extraction
- `is_ancestor_of()` - Ancestry checking
- `reset()` - Counter reset
- `generate_path_between()` - Midpoint generation
- `has_sufficient_gap()` - Gap checking

### ✅ utils/style_converter.rsc
- `camel_to_kebab()` - camelCase to kebab-case conversion
- `convert_style_value()` - Style value conversion
- `convert_style_object_to_css()` - Full style object conversion

### ✅ types/type_conversion.rsc
- `ts_type_to_csharp_type()` - TypeScript to C# type mapping
  - Primitive types (string, number, boolean, any, void)
  - Array types
  - Custom type references
  - @minimact/mvc types (decimal, int, Guid, DateTime, etc.)
- `infer_type()` - C# type inference from literals
  - String literals
  - Numeric literals (int vs double)
  - Boolean literals
  - Array expressions
  - Object expressions

## Adding New Tests

To add a test for a new converted module:

1. Create a test file in the appropriate directory:
   ```
   tests/minimact/<category>/test_<module_name>.rsc
   ```

2. Import the module being tested:
   ```rustscript
   use "../../../rustscript-plugin-minimact/<category>/<module_name>.rsc" {
       function_name1,
       function_name2
   };
   ```

3. Create a plugin with test functions:
   ```rustscript
   plugin TestModuleName {
       fn test_function_name() {
           // Test code here
           let result = function_name(input);
           // result should be expected_value
       }
   }
   ```

4. Add the test file to `test_minimact.py`:
   ```python
   test_modules = {
       "category": [
           "tests/minimact/category/test_module_name.rsc",
       ],
   }
   ```

5. Run the tests:
   ```bash
   python test_minimact.py
   ```

## Test Output

Each test generates output in:
```
tests/minimact/dist/<category>/<test_name>/
├── index.js    # Babel (JavaScript) output
└── lib.rs      # SWC (Rust) output
```

## Notes

- Test files use inline comments to document expected results
- Tests compile to both Babel and SWC to ensure cross-platform compatibility
- The test runner verifies syntax validity but doesn't execute the tests (yet)
- For runtime testing, you would need to set up a Babel/Node.js environment

## Future Improvements

- [ ] Add runtime execution tests for Babel output
- [ ] Add integration tests that compare behavior with original Babel plugin
- [ ] Add tests for analyzer modules
- [ ] Add tests for extractor modules
- [ ] Add tests for generator modules
- [ ] Add snapshot testing for generated code
- [ ] Add performance benchmarks
