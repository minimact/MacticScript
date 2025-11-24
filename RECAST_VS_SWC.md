# Recast (Babel) vs SWC Codegen - Formatting Preservation

## What Recast Does in babel-plugin-minimact

**Purpose:** Generate `.tsx.keys` files with hex paths added while **preserving original formatting**

```javascript
// In index.cjs (lines 96-148)
const recast = require('recast');

// 1. Parse original TSX with Recast (BEFORE Babel transforms JSX)
const originalAst = recast.parse(state.file.originalCode, {
  parser: require('recast/parsers/babel-ts')
});

// 2. Add hex paths to JSX using Recast's visitor
recast.visit(originalAst, {
  visitFunctionDeclaration(funcPath) {
    // Add keys to JSX elements
    assignPathsToJSX(returnNode.argument, '', pathGen, babelTypes);
  }
});

// 3. Print back with formatting preserved!
const output = recast.print(originalAst, {
  tabWidth: 2,
  useTabs: false,
  quote: 'single',
  trailingComma: false
});

// 4. Write .tsx.keys file
fs.writeFileSync(keysFilePath, output.code);
```

### Why This Matters

**For Hot Reload:**
- Developer edits `Counter.tsx`
- Plugin reads `Counter.tsx.keys` (has hex paths from last build)
- Compares old hex paths with new JSX structure
- Detects insertions/deletions
- Preserves developer's formatting in `.keys` file

**Example:**
```tsx
// Original Counter.tsx (developer's formatting):
export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div className="counter">
      <h1>Counter</h1>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>
        Increment
      </button>
    </div>
  );
}

// Generated Counter.tsx.keys (SAME formatting + keys added):
export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div key="10000000" className="counter">
      <h1 key="10000000.20000000">Counter</h1>
      <p key="10000000.30000000">Count: {count}</p>
      <button key="10000000.40000000" onClick={() => setCount(count + 1)}>
        Increment
      </button>
    </div>
  );
}
```

**Without Recast:**
```tsx
// Using @babel/generator - LOSES formatting!
export function Counter(){const[count,setCount]=useState(0);return <div key="10000000" className="counter"><h1 key="10000000.20000000">Counter</h1><p key="10000000.30000000">Count: {count}</p><button key="10000000.40000000" onClick={()=>setCount(count+1)}>Increment</button></div>;}
```

---

## SWC Equivalent: Yes, but Different

### Answer: **SWC CAN preserve comments/formatting, but requires explicit setup**

### Sources:
- [Does swc::Compiler handle comments with full fidelity?](https://github.com/swc-project/swc/discussions/4079)
- [How to generating TypeScript code with SWC](https://stackoverflow.com/questions/70494606/how-to-generating-typescript-code-with-swc)
- [Emitted AST should optionally include comments](https://github.com/swc-project/swc/issues/4165)
- [Does SWC remove comments in the code when transforming?](https://www.answeroverflow.com/m/1327362174980587581)

### How SWC Preserves Comments

```rust
use swc_common::{
    comments::SingleThreadedComments,
    sync::Lrc,
    SourceMap, DUMMY_SP,
};
use swc_ecma_parser::{Parser, StringInput, Syntax};
use swc_ecma_codegen::{Emitter, text_writer::JsWriter};

// 1. Create Comments object
let comments = SingleThreadedComments::default();

// 2. Parse with comments enabled
let mut parser = Parser::new(
    Syntax::Typescript(Default::default()),
    StringInput::new(&src, DUMMY_SP, DUMMY_SP),
    Some(&comments), // ← CRITICAL: Pass comments here
);

let ast = parser.parse_module().unwrap();

// 3. Modify AST (add hex paths, etc.)
// ... your transformations ...

// 4. Print with comments preserved
let mut buf = vec![];
{
    let mut emitter = Emitter {
        cfg: Default::default(),
        cm: Lrc::new(SourceMap::default()),
        comments: Some(&comments), // ← CRITICAL: Pass comments here
        wr: JsWriter::new("\n", &mut buf, None),
    };
    emitter.emit_module(&ast).unwrap();
}

let output = String::from_utf8(buf).unwrap();
```

### Key Differences

| Feature | Recast (Babel) | SWC |
|---------|---------------|-----|
| **Formatting Preservation** | ✅ Automatic | ⚠️ Manual (via comments) |
| **Whitespace** | ✅ Preserved | ❌ Reformatted |
| **Comments** | ✅ Preserved | ✅ Preserved (if configured) |
| **Indentation** | ✅ Original | ❌ Uses configured style |
| **Line breaks** | ✅ Original | ❌ Normalized |
| **Quote style** | ✅ Original | ❌ Configurable only |
| **Use case** | Codemods, AST transforms | Transpilation, minification |

### SWC's Philosophy

**SWC is designed for:**
- **Fast transpilation** (Rust performance)
- **Minification** (doesn't care about formatting)
- **Bundling** (output is optimized, not readable)

**Recast is designed for:**
- **Codemods** (modify code while preserving developer intent)
- **AST refactoring tools** (jscodeshift, etc.)
- **Developer-facing transforms** (keep formatting readable)

---

## Solution for RustScript + Minimact

### Option 1: Hybrid Approach (Recommended)

**For Babel target:**
- Use Recast for `.tsx.keys` generation (preserve formatting)
- Use regular Babel for C# generation (formatting doesn't matter)

**For SWC target:**
- Use SWC parser with comments
- Use SWC emitter with comments
- Accept that formatting will be normalized (not preserved)

### Implementation in RustScript

```rustscript
writer MinimactTranspiler {
    // For Babel: Generate code that uses Recast
    fn generate_babel_keys_file() -> Str {
        "
        const recast = require('recast');
        const originalAst = recast.parse(state.file.originalCode, {
            parser: require('recast/parsers/babel-ts')
        });

        // Add hex paths to JSX
        recast.visit(originalAst, {
            visitReturnStatement(returnPath) {
                assignPathsToJSX(returnNode.argument);
            }
        });

        const output = recast.print(originalAst);
        fs.writeFileSync(keysFilePath, output.code);
        ".to_string()
    }

    // For SWC: Generate code that preserves comments
    fn generate_swc_keys_file() -> Str {
        "
        let comments = SingleThreadedComments::default();
        let mut parser = Parser::new(
            Syntax::Typescript(Default::default()),
            StringInput::new(&original_code, DUMMY_SP, DUMMY_SP),
            Some(&comments),
        );

        let mut ast = parser.parse_module().unwrap();

        // Add hex paths to JSX
        ast.visit_mut_with(&mut HexPathVisitor);

        // Emit with comments (formatting will be normalized)
        let mut buf = vec![];
        {
            let mut emitter = Emitter {
                cfg: Default::default(),
                cm: Lrc::new(cm.clone()),
                comments: Some(&comments),
                wr: JsWriter::new(\"\n\", &mut buf, None),
            };
            emitter.emit_module(&ast).unwrap();
        }

        fs::write(keys_file_path, buf).unwrap();
        ".to_string()
    }
}
```

### Option 2: Babel-Only for .keys Generation

**Simpler approach:**
- Only Babel plugin generates `.tsx.keys` files (uses Recast)
- SWC plugin skips `.keys` generation (or uses Babel's output)
- Both generate C# files (formatting doesn't matter there)

**Why this works:**
- Hot reload typically runs in dev mode (Node.js/Babel)
- Production builds use SWC (don't need `.keys` files)
- `.keys` files are developer-facing (formatting matters)
- C# files are compiler input (formatting irrelevant)

---

## Recommendation

### For Minimact RustScript Plugin:

**Generate different code for Babel vs SWC targets:**

```rustscript
writer MinimactTranspiler {
    fn finish(&self) -> TranspilerOutput {
        let babel_code = self.generate_babel_plugin();
        let swc_code = self.generate_swc_plugin();

        TranspilerOutput {
            babel: babel_code,  // Uses Recast for .keys
            swc: swc_code,      // Uses Comments for .keys
        }
    }

    fn generate_babel_plugin(&self) -> Str {
        // Include Recast-based .keys generation
        format!(r#"
        // In Program.exit:
        if (inputFilePath && state.file.originalCode) {{
            const recast = require('recast');
            const originalAst = recast.parse(state.file.originalCode, {{
                parser: require('recast/parsers/babel-ts')
            }});

            recast.visit(originalAst, {{
                visitReturnStatement(returnPath) {{
                    // Add hex paths
                    assignPathsToJSX(returnNode.argument, '', pathGen, t);
                }}
            }});

            const output = recast.print(originalAst, {{
                tabWidth: 2,
                quote: 'single'
            }});

            fs.writeFileSync(keysFilePath, output.code);
        }}
        "#)
    }

    fn generate_swc_plugin(&self) -> Str {
        // Use SWC comments-based approach
        format!(r#"
        // In SWC plugin:
        let comments = SingleThreadedComments::default();

        // Parse with comments
        let mut parser = Parser::new(
            Syntax::Typescript(Default::default()),
            StringInput::new(&original_code, DUMMY_SP, DUMMY_SP),
            Some(&comments),
        );

        // Transform AST
        let mut module = parser.parse_module().unwrap();
        module.visit_mut_with(&mut HexPathAdder);

        // Emit with comments (normalized formatting)
        let output = emit_module(&module, &comments);
        std::fs::write(keys_file_path, output).unwrap();
        "#)
    }
}
```

---

## Conclusion

**Yes, SWC can preserve comments, but NOT original formatting like Recast does.**

### Trade-offs:

| Aspect | Recast (Babel) | SWC |
|--------|---------------|-----|
| **Formatting** | ✅ Perfect preservation | ❌ Normalized |
| **Comments** | ✅ Preserved | ✅ Preserved (with setup) |
| **Speed** | ⚠️ Slower (JS) | ✅ Fast (Rust) |
| **Use for .keys** | ✅ Ideal | ⚠️ Acceptable |
| **Developer UX** | ✅ Familiar formatting | ⚠️ Different formatting |

### Best Practice:

For Minimact's dual-target approach:
1. **Babel plugin** - Use Recast for `.tsx.keys` (perfect formatting preservation)
2. **SWC plugin** - Use Comments API for `.tsx.keys` (normalized formatting, faster)
3. **Both plugins** - Generate identical C# files (formatting doesn't matter)

Developers using Babel get perfect formatting preservation. Developers using SWC get normalized formatting but much faster builds. Both get identical C# output and hot reload functionality.

This is the best of both worlds! 🎉
