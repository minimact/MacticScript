# RustScript Plugin Minimact

This directory contains the RustScript conversion of the babel-plugin-minimact helper modules.

## Project Structure

```
rustscript-plugin-minimact/
├── utils/
│   ├── helpers.rsc           # General utility functions
│   ├── hex_path.rsc          # Hex path generation for element tracking
│   └── style_converter.rsc   # CSS/style conversion utilities
├── types/
│   └── type_conversion.rsc   # TypeScript to C# type conversion
└── README.md                 # This file
```

## Module Overview

### utils/helpers.rsc

General utility functions used throughout the plugin.

**Exported Functions:**
- `escape_csharp_string(s: &Str) -> Str` - Escapes special characters for C# strings (handles `\`, `"`, `\n`, `\r`, `\t`)
- `get_component_name(node: &FunctionDeclaration, parent: Option<&Statement>) -> Option<Str>` - Extracts component name from function/class declarations
- `is_component_name(name: &Str) -> bool` - Checks if a name is a component name (starts with uppercase)

**Usage:**
```rustscript
use "./utils/helpers.rsc" { escape_csharp_string, get_component_name, is_component_name };

let safe_string = escape_csharp_string("Hello\nWorld");
// Result: "Hello\\nWorld"

let name = get_component_name(func_node, None);
// Result: Some("MyComponent") or None

let is_component = is_component_name("MyComponent");
// Result: true
```

---

### utils/hex_path.rsc

Generates lexicographically sortable, insertion-friendly paths using hex codes.

**Key Features:**
- No renumbering needed when inserting elements
- String comparison works for sorting
- Billions of slots between any two elements
- Easy to visualize tree structure

**Exported Struct:**
```rustscript
pub struct HexPathGenerator {
    pub gap: i32,
    pub counters: HashMap<Str, i32>,
}
```

**Exported Functions:**
- `HexPathGenerator::new(gap: i32) -> HexPathGenerator` - Create with custom gap
- `HexPathGenerator::default() -> HexPathGenerator` - Create with default gap (0x10000000)
- `next(&mut self, parent_path: &Str) -> Str` - Generate next hex code for parent path
- `build_path(&self, parent_path: &Str, child_hex: &Str) -> Str` - Build full path
- `parse_path(&self, path: &Str) -> Vec<Str>` - Parse path into segments
- `get_depth(&self, path: &Str) -> i32` - Get depth of path
- `get_parent_path(&self, path: &Str) -> Option<Str>` - Get parent path
- `is_ancestor_of(&self, ancestor: &Str, descendant: &Str) -> bool` - Check ancestry
- `reset(&mut self, parent_path: &Str)` - Reset counter for specific parent
- `reset_all(&mut self)` - Reset all counters
- `generate_path_between(path1: &Str, path2: &Str) -> Str` - Generate midpoint path (static)
- `has_sufficient_gap(path1: &Str, path2: &Str, min_gap: i32) -> bool` - Check gap (static)

**Usage:**
```rustscript
use "./utils/hex_path.rsc" { HexPathGenerator };

let mut generator = HexPathGenerator::default();

let path1 = generator.next("");           // "1" (root level)
let path2 = generator.next("");           // "2"
let child1 = generator.next(&path1);      // "1"
let full_path = generator.build_path(&path1, &child1);  // "1.1"
```

**Example Hierarchy:**
```
div [10000000]
  span [10000000.1]
  span [10000000.2]
  p [10000000.3]
section [20000000]
```

---

### utils/style_converter.rsc

Converts JavaScript style objects to CSS strings.

**Exported Functions:**
- `camel_to_kebab(s: &Str) -> Str` - Convert camelCase to kebab-case
- `convert_style_value(value: &Expression) -> Str` - Convert a style value to CSS string
- `convert_style_object_to_css(object_expr: &ObjectExpression) -> Result<Str, Str>` - Convert full style object to CSS

**Usage:**
```rustscript
use "./utils/style_converter.rsc" { camel_to_kebab, convert_style_object_to_css };

let css_prop = camel_to_kebab("marginTop");
// Result: "margin-top"

// Given a JavaScript object: { marginTop: '12px', color: 'red' }
let css = convert_style_object_to_css(style_object)?;
// Result: "margin-top: 12px; color: red"
```

**Conversion Rules:**
- String literals: use value directly
- Numeric literals: append 'px' (e.g., `12` → `"12px"`)
- Identifiers: use identifier name
- camelCase properties are converted to kebab-case

---

### types/type_conversion.rsc

Converts TypeScript type annotations to C# types and infers C# types from JavaScript values.

**Exported Functions:**
- `ts_type_to_csharp_type(ts_type: &TSType) -> Str` - Convert TypeScript type to C# type
- `infer_type(node: &Expression) -> Str` - Infer C# type from literal value

**TypeScript to C# Type Mappings:**

| TypeScript | C# |
|------------|-----|
| `string` | `string` |
| `number` | `double` |
| `boolean` | `bool` |
| `any` | `dynamic` |
| `T[]` | `List<T>` |
| `object` types | `dynamic` |

**@minimact/mvc Type Mappings:**

| @minimact/mvc | C# |
|---------------|-----|
| `decimal` | `decimal` |
| `int`, `int32` | `int` |
| `int64`, `long` | `long` |
| `float`, `float32` | `float` |
| `float64`, `double` | `double` |
| `short`, `int16` | `short` |
| `byte` | `byte` |
| `Guid` | `Guid` |
| `DateTime` | `DateTime` |
| `DateOnly` | `DateOnly` |
| `TimeOnly` | `TimeOnly` |

**Usage:**
```rustscript
use "./types/type_conversion.rsc" { ts_type_to_csharp_type, infer_type };

// Convert TypeScript type annotation
let csharp_type = ts_type_to_csharp_type(ts_type_node);
// Example: TSStringKeyword -> "string"
// Example: TSArrayType<number> -> "List<double>"

// Infer type from value
let inferred = infer_type(expression);
// Example: NumericLiteral(42) -> "int"
// Example: NumericLiteral(3.14) -> "double"
// Example: StringLiteral("hello") -> "string"
```

---

## Building

To compile these RustScript modules to both Babel and SWC targets:

```bash
rustscript build
```

Or compile to specific targets:

```bash
rustscript build --target babel    # JavaScript only
rustscript build --target swc      # Rust/WASM only
```

---

## Notes

### Differences from Original Babel Plugin

1. **Explicit Cloning**: RustScript requires explicit `.clone()` when extracting values from references
2. **Option Types**: Nullable values use `Option<T>` instead of `null`/`undefined`
3. **Pattern Matching**: Uses `match` and `if let` instead of type checking with `t.is*()` functions
4. **Mutability**: Variables that change must be declared with `let mut`
5. **Error Handling**: Uses `Result<T, E>` instead of exceptions

### Type System

- `Str` - Platform-agnostic string type (maps to `string` in JS, `String` in Rust)
- `i32` - 32-bit signed integer
- `f64` - 64-bit floating point
- `bool` - Boolean
- `Vec<T>` - Dynamic array
- `HashMap<K, V>` - Key-value map
- `Option<T>` - Optional value (Some/None)
- `Result<T, E>` - Success/Error result

---

## Contributing

When adding new helper functions:

1. Create the module file in the appropriate directory (`utils/`, `types/`, etc.)
2. Use `pub fn` for exported functions
3. Add comprehensive documentation comments
4. Follow RustScript naming conventions (snake_case for functions, PascalCase for types)
5. Update this README with the new module documentation

---

## References

- [RustScript Specification](../rustscript-specification.md)
- [Babel to RustScript Conversion Guide](../babel-to-rustscript.md)
- [Original Babel Plugin](../babel-plugin-minimact/)
