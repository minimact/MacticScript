# Minimact Integration Guide

## Overview

This guide explains how `minimact_full.rsc` integrates with the converted helper modules from `rustscript-plugin-minimact/`.

## Architecture

```
minimact_full.rsc (Main Transpiler)
    ↓
    Uses helper modules:
    ├── utils/helpers.rsc          (String escaping, component detection)
    ├── utils/hex_path.rsc         (Element path generation)
    ├── utils/style_converter.rsc  (CSS conversion)
    ├── types/type_conversion.rsc  (TypeScript → C# types)
    ├── analyzers/*.rsc            (Pattern detection, classification)
    ├── extractors/*.rsc           (Template extraction, binding analysis)
    └── generators/*.rsc           (C# code generation)
```

## Current State

### ✅ What's Already Converted and Tested (11/11 tests passing)

**Utils:**
- ✅ `helpers.rsc` - String escaping, component name detection
- ✅ `hex_path.rsc` - Hex path generation for stable element IDs
- ✅ `style_converter.rsc` - camelCase → kebab-case conversion

**Types:**
- ✅ `type_conversion.rsc` - TypeScript → C# type mapping

**Analyzers:**
- ✅ `classification.rsc` - Node classification (static/client/server/hybrid)
- ✅ `detection.rsc` - Pattern detection (spread props, dynamic children)
- ✅ `hook_detector.rsc` - Custom hook detection

**Extractors:**
- ✅ `is_simple_expression.rsc` - Expression classification
- ✅ `build_member_path.rsc` - Member expression path building

**Generators:**
- ✅ `string_methods.rsc` - JavaScript → C# method conversion

**Integration:**
- ✅ `test_minimact_full.rsc` - Integration test

## Integration Points

### 1. String Escaping (NEEDS UPDATE)

**Current code** in `minimact_full.rsc:334`:
```rustscript
fn expr_to_csharp(expr: &Expr) -> Str {
    if matches!(expr, StringLiteral) {
        return format!("\"{}\"", expr.value);  // ❌ No escaping!
    }
    ...
}
```

**Should be:**
```rustscript
use "../rustscript-plugin-minimact/utils/helpers.rsc" { escape_csharp_string };

fn expr_to_csharp(expr: &Expr) -> Str {
    if matches!(expr, StringLiteral) {
        // ✅ Properly escaped for C#
        return format!("\"{}\"", escape_csharp_string(&expr.value));
    }
    ...
}
```

**Why:** The `escape_csharp_string()` function properly escapes:
- `\` → `\\`
- `"` → `\"`
- `\n` → `\\n`
- `\r` → `\\r`
- `\t` → `\\t`

### 2. Component Name Detection (NEEDS UPDATE)

**Current code** in `minimact_full.rsc:199-206`:
```rustscript
fn is_pascal_case(name: &Str) -> bool {
    if name.len() == 0 {
        return false;
    }
    let first_char = name.chars().next().unwrap();
    return first_char.is_uppercase();
}
```

**Should be:**
```rustscript
use "../rustscript-plugin-minimact/utils/helpers.rsc" { is_component_name };

// Replace is_pascal_case() calls with is_component_name()
```

**Why:** DRY principle - reuse tested logic instead of duplicating.

### 3. Type Inference (NEEDS UPDATE)

**Current code** in `minimact_full.rsc:352-373`:
```rustscript
fn infer_csharp_type(expr: &Expr) -> Str {
    if matches!(expr, StringLiteral) {
        return "string".to_string();
    } else if matches!(expr, NumericLiteral) {
        let val = expr.value;
        if val == val.floor() {
            return "int".to_string();
        } else {
            return "double".to_string();
        }
    }
    ...
}
```

**Should be:**
```rustscript
use "../rustscript-plugin-minimact/types/type_conversion.rsc" { infer_type };

// Replace infer_csharp_type() with direct call to infer_type()
```

**Why:** The `type_conversion.rsc` module:
- Handles all literal types (string, number, boolean, null)
- Differentiates integers vs floats correctly
- Supports array and object inference
- Handles @minimact/mvc special types (decimal, Guid, DateTime, etc.)

### 4. Hex Path Integration (RECOMMENDED)

**Current state:** Not yet integrated

**Recommendation:**
```rustscript
use "../rustscript-plugin-minimact/utils/hex_path.rsc" { HexPathGenerator };

writer MinimactTranspiler {
    struct State {
        // Add hex path generator to state
        hex_path_gen: HexPathGenerator,
        ...
    }

    fn init() -> State {
        State {
            hex_path_gen: HexPathGenerator::default(),
            ...
        }
    }

    // Use when generating VNode tree
    fn generate_vnode_tree(...) {
        let element_path = self.hex_path_gen.next(&parent_path);
        // Assign to element for stable identity
    }
}
```

**Why:** Minimact's architecture depends on stable hex paths for:
- Predictive patch targeting
- Hot reload state preservation
- Precise DOM updates

### 5. Style Conversion (RECOMMENDED)

**Recommendation:**
```rustscript
use "../rustscript-plugin-minimact/utils/style_converter.rsc" {
    camel_to_kebab,
    convert_style_object_to_css
};

// When encountering JSX style attributes:
fn visit_jsx_attribute(attr: &JSXAttribute) {
    if attr.name == "style" {
        if let Some(obj) = attr.value.as_object() {
            let css = convert_style_object_to_css(obj)?;
            // Emit CSS string to C# code
        }
    }
}
```

**Why:** Minimact converts inline React styles to CSS strings for server-side rendering.

### 6. Pattern Detection (RECOMMENDED)

**Recommendation:**
```rustscript
use "../rustscript-plugin-minimact/analyzers/detection.rsc" {
    has_spread_props,
    has_dynamic_children
};

use "../rustscript-plugin-minimact/analyzers/classification.rsc" {
    classify_node,
    Dependency
};

fn analyze_jsx_element(elem: &JSXElement) {
    // Check for dynamic patterns
    if has_spread_props(&elem.opening_element.attributes) {
        // Mark component as having dynamic props
    }

    if has_dynamic_children(&elem.children) {
        // Mark component as having dynamic children
    }

    // Classify based on dependencies
    let deps = collect_dependencies(elem);
    let classification = classify_node(&deps);
    // classification: "static", "client", "server", or "hybrid"
}
```

**Why:** Proper classification enables:
- Optimal code generation (static vs dynamic)
- Prediction system optimization
- Client vs server rendering decisions

## Refactoring Roadmap

### Phase 1: Replace Duplicated Utilities ✅ READY
- Replace `is_pascal_case` with `is_component_name` from `helpers.rsc`
- Replace `expr_to_csharp` string handling with `escape_csharp_string`
- Replace `infer_csharp_type` with `infer_type` from `type_conversion.rsc`

### Phase 2: Add Hex Path Support
- Integrate `HexPathGenerator` into writer state
- Generate hex paths for all JSX elements
- Emit hex paths in generated C# VNode tree

### Phase 3: Add Style Conversion
- Use `convert_style_object_to_css` for style attributes
- Generate CSS strings in C# code

### Phase 4: Add Pattern Detection
- Use `has_spread_props` and `has_dynamic_children` for analysis
- Use `classify_node` for server/client classification
- Generate optimized code based on classification

### Phase 5: Add Full Extractor Integration
- Integrate template extraction from `extractors/` modules
- Use `extract_ternary_element_template` for conditionals
- Use `extract_logical_and_element_template` for logical expressions

### Phase 6: Add Full Generator Integration
- Use `generators/` modules for C# code generation
- Generate method calls using `handle_string_methods`
- Generate proper C# expressions for all JavaScript patterns

## Example: Fully Integrated minimact_full.rsc

```rustscript
/// Minimact TSX to C# Transpiler (Integrated Version)

use fs;
use json;

// Import helper modules
use "../rustscript-plugin-minimact/utils/helpers.rsc" {
    escape_csharp_string,
    is_component_name
};
use "../rustscript-plugin-minimact/utils/hex_path.rsc" { HexPathGenerator };
use "../rustscript-plugin-minimact/types/type_conversion.rsc" {
    infer_type,
    ts_type_to_csharp_type
};
use "../rustscript-plugin-minimact/analyzers/classification.rsc" {
    classify_node,
    Dependency
};
use "../rustscript-plugin-minimact/analyzers/detection.rsc" {
    has_spread_props,
    has_dynamic_children
};

writer MinimactTranspiler {
    struct State {
        csharp: CodeBuilder,
        templates: HashMap<Str, Template>,
        hooks: Vec<HookSignature>,
        hex_path_gen: HexPathGenerator,  // ✨ Added
        current_component: Option<ComponentInfo>,
        components: Vec<ComponentInfo>,
    }

    fn init() -> State {
        State {
            csharp: CodeBuilder::new(),
            templates: HashMap::new(),
            hooks: vec![],
            hex_path_gen: HexPathGenerator::default(),  // ✨ Added
            current_component: None,
            components: vec![],
        }
    }

    pub fn visit_function_declaration(node: &FunctionDeclaration) {
        let name = node.id.name.clone();

        // ✅ Use helper instead of local function
        if !is_component_name(&name) {
            return;
        }

        let mut component = ComponentInfo::new(name.clone());

        if node.params.len() > 0 {
            extract_props(&node.params[0], &mut component);
        }

        if let Some(body) = &node.body {
            traverse(body) capturing [&mut component] {
                fn visit_variable_declarator(decl: &VariableDeclarator) {
                    if let Some(init) = &decl.init {
                        if matches!(init, CallExpression) {
                            extract_hook_from_call(init, &decl.id, &mut component);
                        }
                    }
                }

                fn visit_return_statement(ret: &ReturnStatement) {
                    if let Some(arg) = &ret.argument {
                        if matches!(arg, JSXElement) {
                            component.render_body = Some(arg.clone());
                        }
                    }
                }
            }
        }

        self.components.push(component);
    }

    fn finish(&self) -> TranspilerOutput {
        let mut csharp_code = String::new();

        for component in &self.components {
            let code = generate_csharp_class(&component);
            csharp_code.push_str(&code);
            csharp_code.push_str("\n");
        }

        let mut all_templates: HashMap<Str, Template> = HashMap::new();
        for component in &self.components {
            for (key, template) in &component.templates {
                let full_key = format!("{}.{}", component.name, key);
                all_templates.insert(full_key, template.clone());
            }
        }

        TranspilerOutput {
            csharp: csharp_code,
            templates: json::to_string_pretty(&all_templates).unwrap(),
            hooks: json::to_string_pretty(&self.hooks).unwrap(),
        }
    }
}

// Helper Functions (Updated to use modules)

fn expr_to_csharp(expr: &Expr) -> Str {
    if matches!(expr, StringLiteral) {
        // ✅ Properly escape C# strings
        return format!("\"{}\"", escape_csharp_string(&expr.value));
    } else if matches!(expr, NumericLiteral) {
        return expr.value.to_string();
    } else if matches!(expr, BooleanLiteral) {
        return if expr.value { "true" } else { "false" }.to_string();
    } else if matches!(expr, NullLiteral) {
        return "null".to_string();
    } else if matches!(expr, Identifier) {
        return expr.name.clone();
    } else if matches!(expr, ArrayExpression) {
        return "new List<dynamic>()".to_string();
    } else if matches!(expr, ObjectExpression) {
        return "new Dictionary<string, dynamic>()".to_string();
    }

    return "null".to_string();
}

// ✅ Use helper module instead of local implementation
// (Remove infer_csharp_type, just call infer_type directly)
```

## Testing Strategy

All helper modules have comprehensive tests in `src/rustscript/tests/minimact/`:

- ✅ `utils/test_helpers.rsc` - String escaping, component detection
- ✅ `utils/test_hex_path.rsc` - Hex path generation
- ✅ `utils/test_style_converter_integration.rsc` - Style conversion
- ✅ `types/test_type_conversion_integration.rsc` - Type mapping
- ✅ `analyzers/test_classification.rsc` - Node classification
- ✅ `analyzers/test_detection.rsc` - Pattern detection
- ✅ `analyzers/test_hook_detector.rsc` - Hook detection
- ✅ `extractors/test_is_simple_expression.rsc` - Expression analysis
- ✅ `extractors/test_build_member_path.rsc` - Path building
- ✅ `generators/test_string_methods.rsc` - Code generation
- ✅ `integration/test_minimact_full.rsc` - Integration test

Run all tests:
```bash
cd src/rustscript
python test_minimact.py
```

## Benefits of Integration

### 1. Code Reuse
- ✅ No duplicated logic
- ✅ Single source of truth for each concern
- ✅ Easier maintenance

### 2. Correctness
- ✅ All helpers are tested (11/11 tests passing)
- ✅ Edge cases handled (string escaping, type inference, etc.)
- ✅ Consistent behavior across codebase

### 3. Modularity
- ✅ Each module has a single responsibility
- ✅ Easy to extend with new features
- ✅ Clear separation of concerns

### 4. Dual-Target Compilation
- ✅ Same code generates both Babel and SWC plugins
- ✅ Unified codebase for JavaScript and Rust
- ✅ Consistency guaranteed

## Next Steps

1. **Refactor minimact_full.rsc** to use helper modules
2. **Add more helper modules** for remaining babel-plugin-minimact features
3. **Expand test coverage** for complex integration scenarios
4. **Generate full Minimact transpiler** from RustScript

## Conclusion

The converted helper modules are production-ready and tested. Integrating them into `minimact_full.rsc` will:
- Eliminate code duplication
- Improve correctness
- Enable dual-target (Babel + SWC) transpilation
- Maintain consistency with the original babel-plugin-minimact

All 11 tests passing demonstrates the conversion is successful! 🎉
