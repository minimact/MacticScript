# Minimum Dependencies for Counter.tsx Transpilation

## Goal
Successfully transpile `Counter.tsx` to C# using RustScript, generating output that matches the expected format from `minimact/plugin/README.md`.

## Counter.tsx Requirements

```tsx
import { useState, useEffect, useRef } from '@minimact/core';

export function Counter() {
  const [count, setCount] = useState(0);           // ← useState extraction
  const buttonRef = useRef(null);                  // ← useRef extraction

  useEffect(() => {                                 // ← useEffect extraction
    console.log(`Count changed to: ${count}`);      // ← Template literal → C# interpolation
  }, [count]);                                      // ← Dependencies extraction

  const increment = () => {                         // ← Event handler extraction
    setCount(count + 1);                            // ← setState call → C# SetState
  };

  return (                                          // ← JSX → VNode tree
    <div className="counter">
      <h1>Counter</h1>
      <p>Count: {count}</p>
      <button ref={buttonRef} onClick={increment}>
        Increment
      </button>
    </div>
  );
}
```

## Minimum RustScript Modules Needed

### 1. **Hook Extraction** (`extract_hooks.rsc`)

**What it does:**
- Detects `useState`, `useEffect`, `useRef` calls
- Extracts variable names, initial values, dependencies

**Input:**
```javascript
const [count, setCount] = useState(0);
```

**Output:**
```rust
StateField {
    name: "count",
    setter: "setCount",
    initial_value: "0",
    csharp_type: "int"
}
```

**Dependencies:**
- Type inference (number → int)
- Pattern matching (array destructuring)

---

### 2. **Type Inference** (`infer_type.rsc`)

**What it does:**
- Maps JavaScript values → C# types
- Handles literals, arrays, objects

**Mappings:**
```
0              → int
3.14           → double
"hello"        → string
true           → bool
[]             → List<dynamic>
{}             → Dictionary<string, dynamic>
null           → null
```

**Dependencies:**
- None (standalone)

---

### 3. **JSX → VNode Conversion** (`jsx_to_vnode.rsc`)

**What it does:**
- Converts JSX elements → C# VElement calls
- Handles attributes, children, expressions

**Input:**
```jsx
<div className="counter">
  <h1>Counter</h1>
  <p>Count: {count}</p>
</div>
```

**Output:**
```csharp
new VElement("div", new Dictionary<string, string>
{
    ["className"] = "counter"
}, new VNode[]
{
    new VElement("h1", "Counter"),
    new VElement("p", $"Count: {count}")
})
```

**Dependencies:**
- String escaping (for attribute values)
- Expression → C# conversion

---

### 4. **Expression Conversion** (`expr_to_csharp.rsc`)

**What it does:**
- Converts JavaScript expressions → C# expressions
- Handles identifiers, literals, operators, template literals

**Examples:**
```
count + 1              → count + 1
`Count: ${count}`      → $"Count: {count}"
console.log("hi")      → Console.WriteLine("hi")
```

**Dependencies:**
- String escaping

---

### 5. **Event Handler Extraction** (`extract_event_handlers.rsc`)

**What it does:**
- Detects inline arrow functions and named functions
- Converts camelCase → PascalCase for C# methods
- Extracts setState calls → SetState method calls

**Input:**
```jsx
const increment = () => {
  setCount(count + 1);
};

<button onClick={increment}>
```

**Output:**
```csharp
private void Increment()
{
    SetState(nameof(count), count + 1);
}

// In VElement:
["onClick"] = "Increment"
```

**Dependencies:**
- Expression conversion
- Function body analysis

---

### 6. **C# Code Generation** (`generate_csharp.rsc`)

**What it does:**
- Assembles all extracted parts into a C# class
- Generates proper structure, attributes, methods

**Structure:**
```csharp
using Minimact;
using System;
using System.Collections.Generic;

namespace Generated.Components
{
    [MinimactComponent]
    public class Counter : MinimactComponent
    {
        // useState fields
        [UseState(0)]
        private int count;

        // useRef fields
        [UseRef(null)]
        private ElementRef buttonRef;

        // useEffect methods
        [UseEffect("count")]
        private void Effect_0() { ... }

        // Render method
        protected override VNode Render() { ... }

        // Event handlers
        private void Increment() { ... }
    }
}
```

---

## Dependency Graph

```
generate_csharp.rsc
    ├── extract_hooks.rsc
    │   └── infer_type.rsc
    ├── extract_event_handlers.rsc
    │   └── expr_to_csharp.rsc
    │       └── escape_string.rsc
    └── jsx_to_vnode.rsc
        ├── expr_to_csharp.rsc
        └── escape_string.rsc
```

## Total: 7 Core Modules

1. `escape_string.rsc` - String escaping for C#
2. `infer_type.rsc` - JavaScript → C# type mapping
3. `expr_to_csharp.rsc` - Expression conversion
4. `extract_hooks.rsc` - Hook extraction (useState, useEffect, useRef)
5. `extract_event_handlers.rsc` - Event handler extraction
6. `jsx_to_vnode.rsc` - JSX → VNode conversion
7. `generate_csharp.rsc` - Final C# class assembly

## What We Built

✅ **`simple_counter_transpiler.rsc`** - Compiles successfully!
- Extracts `useState` → C# fields
- Extracts `useRef` → C# fields
- Extracts `useEffect` → C# methods (with dependencies)
- Generates basic C# class structure

## What's Missing (To Match Expected Output)

1. **JSX → VNode tree generation** - Currently stubbed out
2. **Event handler body conversion** - Currently stubbed out
3. **Template literal → C# string interpolation** - Partially working
4. **setState call → SetState method call** - Not implemented

## Next Steps

1. Add JSX traversal to convert elements → VNode calls
2. Add function body conversion (statements → C# statements)
3. Add setState detection and conversion
4. Test on Counter.tsx and compare with expected output

## Comparison: simple_counter_transpiler.rsc vs Full minimact_full_refactored_v2.rsc

| Feature | simple_counter_transpiler.rsc | minimact_full_refactored_v2.rsc |
|---------|-------------------------------|----------------------------------|
| **Lines of code** | ~260 | ~900 |
| **Compiles?** | ✅ Yes | ✅ Yes |
| **Extracts useState** | ✅ Yes | ✅ Yes |
| **Extracts useRef** | ✅ Yes | ✅ Yes |
| **Extracts useEffect** | ✅ Yes | ✅ Yes |
| **Generates C# structure** | ✅ Basic | ✅ Full |
| **JSX → VNode** | ❌ Stubbed | ✅ Implemented |
| **Event handlers** | ❌ Stubbed | ✅ Implemented |
| **Hex paths** | ❌ No | ✅ Yes |
| **Template system** | ❌ No | ⚠️ Partial |
| **Uses helper modules** | ❌ No | ✅ Yes |

## Recommendation

**Use `minimact_full_refactored_v2.rsc` as the foundation** and add the missing pieces:

1. Complete JSX → VNode generation
2. Complete event handler body conversion
3. Add template extraction (for prediction system)
4. Integrate all helper modules from `rustscript-plugin-minimact/`

The simple transpiler proves the concept works - now build on the full one!
