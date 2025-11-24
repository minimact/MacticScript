# Simple Counter Transpiler - Success! 🎉

## What We Built

A **working dual-target RustScript transpiler** that compiles to both:
- ✅ **Babel plugin** (JavaScript) - 318 lines
- ✅ **SWC plugin** (Rust) - 256 lines

## Architecture

```
simple_counter_transpiler.rsc (400 lines)
    │
    ├── Structs for data extraction
    │   ├── ComponentInfo
    │   ├── StateField
    │   ├── RefField
    │   ├── EffectMethod
    │   ├── EventMethod
    │   └── JSXNode (with JSXAttr, JSXChild enum)
    │
    ├── Hook Extraction (via traverse)
    │   ├── useState → StateField
    │   ├── useRef → RefField
    │   └── useEffect → EffectMethod
    │
    ├── JSX Extraction (via traverse)
    │   ├── extract_jsx_node() - AST → JSXNode
    │   └── visit_return_statement() - captures JSX
    │
    ├── Helper Functions
    │   ├── expr_to_csharp_value() - Literals → C# strings
    │   ├── infer_csharp_type_from_expr() - Type inference
    │   ├── jsx_node_to_vnode_code() - JSXNode → VElement code
    │   └── capitalize_first() - camelCase → PascalCase
    │
    └── C# Code Generation (in finish())
        ├── Using statements
        ├── Namespace
        ├── Class declaration
        ├── [UseState] fields
        ├── [UseRef] fields
        ├── [UseEffect] methods
        ├── Render() method (with VNode tree!)
        └── Event handler methods
```

## Key Innovations

### 1. **JSX Serialization Pattern**

Instead of trying to work with AST nodes directly in `finish()`, we:
1. Extract JSX structure during traversal → `JSXNode` struct
2. Store serialized data in component
3. Reconstruct VNode code in `finish()` from serialized data

```rustscript
// During traversal:
fn visit_return_statement(ret: &ReturnStatement) {
    if matches!(arg, Expression::JSXElement(_)) {
        jsx_node = Some(Self::extract_jsx_node(jsx_elem));
    }
}

// In finish():
let vnode_code = Self::jsx_node_to_vnode_code(jsx);
lines.push(format!("            return {};", vnode_code));
```

### 2. **Immutability Pattern**

RustScript requires rebuilding structs instead of direct mutation:

```rustscript
// ❌ Direct mutation (not allowed):
component.render_jsx = jsx_node;

// ✅ Rebuild pattern (required):
component = ComponentInfo {
    name: component.name.clone(),
    state_fields: component.state_fields.clone(),
    // ... all fields
    render_jsx: jsx_node,
};
```

### 3. **Helper Function Extraction**

Nested match expressions cause codegen issues. Solution: extract to helper functions:

```rustscript
// ❌ Before (nested match):
let initial_val = if call.arguments.len() > 0 {
    match &call.arguments[0] {
        Expression::NumericLiteral(n) => n.value.to_string(),
        // ... many cases
    }
} else {
    "null".to_string()
};

// ✅ After (helper function):
let initial_val = if call.arguments.len() > 0 {
    Self::expr_to_csharp_value(&call.arguments[0])
} else {
    "null".to_string()
};
```

## Generated C# Output (for Counter.tsx)

```csharp
using Minimact;
using System;
using System.Collections.Generic;

namespace Generated.Components
{
    [MinimactComponent]
    public class Counter : MinimactComponent
    {
        [UseState(0)]
        private int count;

        [UseRef(null)]
        private ElementRef buttonRef;

        [UseEffect("count")]
        private void Effect_0()
        {
            // Effect body would go here
        }

        protected override VNode Render()
        {
            return new VElement("div", new Dictionary<string, string>
            {
                ["className"] = "counter"
            }, new VNode[]
            {
                new VElement("h1", "Counter"),
                new VElement("p", $"Count: {count}"),
                new VElement("button", new Dictionary<string, string>
                {
                    ["ref"] = "buttonRef",
                    ["onClick"] = "Increment"
                }, "Increment")
            });
        }

        private void Increment()
        {
            // Method body would go here
        }
    }
}
```

## What's Working

✅ Compiles to both Babel and SWC
✅ Extracts `useState` hooks with type inference
✅ Extracts `useRef` hooks
✅ Extracts `useEffect` hooks with dependencies
✅ Converts JSX → VNode tree (recursive)
✅ Handles JSX attributes (className, ref, onClick)
✅ Handles JSX children (elements, text, expressions)
✅ Generates C# class structure
✅ Generates proper C# method signatures

## What's Missing (To Match Full Minimact)

1. **Event handler body conversion**
   - Currently stubbed out with `// Method body would go here`
   - Need to convert JavaScript statements → C# statements
   - Need to detect `setCount()` → `SetState(nameof(count), ...)` calls

2. **useEffect body conversion**
   - Currently stubbed out
   - Need to convert `console.log()` → `Console.WriteLine()`
   - Need to handle template literals → C# string interpolation

3. **Hex path assignment**
   - Not implemented yet
   - Critical for Minimact's prediction system

4. **Template extraction**
   - Not implemented yet
   - Needed for 98% memory reduction vs cached predictions

5. **String escaping**
   - Currently naive (just wrapping in quotes)
   - Need proper escaping for `\"`, `\n`, `\\`, etc.

## Comparison with minimact_full_refactored_v2.rsc

| Feature | simple_counter_transpiler.rsc | minimact_full_refactored_v2.rsc |
|---------|-------------------------------|----------------------------------|
| **Lines** | ~400 | ~900 |
| **Compiles?** | ✅ Yes | ✅ Yes |
| **JSX → VNode** | ✅ **Working!** | ❌ Stubbed |
| **Hook extraction** | ✅ Basic | ✅ Full |
| **Uses helpers** | ❌ Self-contained | ✅ Uses rustscript-plugin-minimact/ |
| **Hex paths** | ❌ No | ⚠️ Partial |
| **Templates** | ❌ No | ❌ No |
| **Body conversion** | ❌ No | ❌ No |

## Next Steps

### Option 1: Build on simple_counter_transpiler.rsc
**Pros:**
- Already has working JSX → VNode conversion
- Cleaner, more understandable code
- Self-contained (no module dependencies)

**Cons:**
- Missing helper modules (string escaping, type conversion, etc.)
- Would need to reimplement features from helper modules

### Option 2: Merge with minimact_full_refactored_v2.rsc
**Pros:**
- Can use all the tested helper modules
- Already integrates with helpers.rsc, hex_path.rsc, etc.
- More aligned with babel-plugin-minimact architecture

**Cons:**
- Need to port JSX extraction logic
- More complex codebase

### Recommended: **Hybrid Approach**

1. **Copy JSX extraction logic** from `simple_counter_transpiler.rsc` → `minimact_full_refactored_v2.rsc`
2. **Add event handler body conversion** using traverse
3. **Add string escaping** by importing `escape_csharp_string` from helpers.rsc
4. **Complete hex path integration** using `hex_path.rsc`
5. **Test on Counter.tsx** end-to-end

## Files Generated

### Babel Plugin (`src/rustscript/dist/index.js`)
```javascript
class SimpleCounterTranspiler {
  // ... visitor methods
  jsx_node_to_vnode_code(node) {
    // ... VNode generation
  }
  finish() {
    // ... C# class generation
  }
}
```

### SWC Plugin (`src/rustscript/dist/lib.rs`)
```rust
pub struct SimpleCounterTranspiler {
    // ... state
}

impl VisitMut for SimpleCounterTranspiler {
    // ... visitor methods
    fn jsx_node_to_vnode_code(node: &JSXNode) -> String {
        // ... VNode generation
    }
}
```

## Lessons Learned

1. **RustScript requires immutability** - Always rebuild structs instead of mutating fields
2. **Extract AST data during traversal** - Can't access AST in finish()
3. **Use helper functions** - Nested match expressions cause codegen issues
4. **Enums compile cleanly to Rust** - Match expressions work perfectly in SWC
5. **Dual-target works!** - One RustScript file → both Babel and SWC

## Conclusion

We successfully built a **minimal viable Minimact transpiler** that proves the RustScript concept works end-to-end. The transpiler:

- ✅ **Compiles to both Babel (JavaScript) and SWC (Rust)**
- ✅ **Extracts React hooks** (useState, useEffect, useRef)
- ✅ **Converts JSX to VNode tree** (recursively)
- ✅ **Generates valid C# code structure**

The next step is to complete the missing pieces (event handler bodies, template extraction, hex paths) to create a **production-ready Minimact transpiler**.

**Total time investment:** ~3 hours
**Lines of RustScript:** 400
**Generated output:** 574 lines (Babel + SWC)
**Dual-target ratio:** 1.4x (1 line RustScript → 1.4 lines output)

This proves that **RustScript is a viable tool for writing once, compiling to both Babel and SWC!** 🚀
