# Babel Plugin Minimact - Structure & RustScript Conversion

## Overview

The babel-plugin-minimact has a clear modular structure that should be mirrored in the RustScript conversion.

## Architecture

```
babel-plugin-minimact/
├── index.cjs                    # Main plugin entry point (Babel visitor)
└── src/
    ├── processComponent.cjs     # Component/hook processing orchestrator
    ├── utils/
    │   ├── helpers.cjs          # ✅ CONVERTED → helpers.rsc
    │   ├── hexPath.cjs          # ✅ CONVERTED → hex_path.rsc
    │   ├── pathAssignment.cjs   # TODO: Convert
    │   └── styleConverter.cjs   # ✅ CONVERTED → style_converter.rsc
    ├── types/
    │   └── typeConversion.cjs   # ✅ CONVERTED → type_conversion.rsc
    ├── analyzers/
    │   ├── analyzePluginUsage.cjs
    │   ├── classification.cjs   # ✅ CONVERTED → classification.rsc
    │   ├── dependencies.cjs     # ✅ CONVERTED → dependencies.rsc
    │   ├── detection.cjs        # ✅ CONVERTED → detection.rsc
    │   ├── hookAnalyzer.cjs     # ✅ CONVERTED → hook_analyzer.rsc
    │   ├── hookDetector.cjs     # ✅ CONVERTED → hook_detector.rsc
    │   ├── hookImports.cjs      # ✅ CONVERTED → hook_imports.rsc
    │   ├── propTypeInference.cjs # ✅ CONVERTED → prop_type_inference.rsc
    │   └── timelineAnalyzer.cjs # ✅ CONVERTED → timeline_analyzer.rsc
    ├── extractors/
    │   ├── hooks.cjs
    │   ├── localVariables.cjs
    │   ├── templates.cjs
    │   ├── loopTemplates.cjs
    │   ├── structuralTemplates.cjs
    │   ├── conditionalElementTemplates/ # ✅ Many files CONVERTED
    │   └── expressionTemplates/        # ✅ Many files CONVERTED
    └── generators/
        ├── csharpFile.cjs
        ├── hookClassGenerator.cjs
        └── expressions/                # ✅ Many files CONVERTED
            └── calls/                  # ✅ CONVERTED → string_methods.rsc, etc.
```

## Flow: index.cjs

**Purpose:** Babel plugin entry point - sets up visitor pattern

### Key Responsibilities

1. **Plugin Initialization** (`pre` hook)
   - Save original source code (before JSX transformation)
   - Used for `.tsx.keys` file generation

2. **Program Enter**
   - Initialize component array
   - Collect top-level helper functions

3. **Function Visitor**
   - Call `processComponent()` for each function
   - Detect components vs regular functions

4. **Program Exit**
   - Generate `.tsx.keys` file (hex paths added to JSX)
   - Generate C# files
   - Generate template JSON
   - Generate hooks JSON
   - Generate structural changes JSON

### RustScript Equivalent

```rustscript
// This would be in a plugin (not writer) in RustScript
plugin MinimactBabelPlugin {
    struct State {
        components: Vec<ComponentInfo>,
        original_code: Option<Str>,
        hex_path_gen: HexPathGenerator,
    }

    fn init() -> State {
        State {
            components: vec![],
            original_code: None,
            hex_path_gen: HexPathGenerator::default(),
        }
    }

    // Pre-hook equivalent
    fn visit_program_enter(prog: &mut Program, ctx: &Context) {
        // Save original code
        self.original_code = Some(ctx.source_code.clone());
    }

    fn visit_function_declaration(func: &mut FunctionDeclaration, ctx: &Context) {
        // Process component
        if let Some(component) = process_component(func, &self) {
            self.components.push(component);
        }
    }

    fn visit_program_exit(prog: &mut Program, ctx: &Context) {
        // Generate all output files
        for component in &self.components {
            generate_csharp_file(component);
            generate_template_json(component);
            generate_hooks_json(component);
        }
    }
}
```

## Flow: processComponent.cjs

**Purpose:** Main component processing logic

### Key Responsibilities (in order)

1. **Component Name Detection** (line 35)
   ```javascript
   const componentName = getComponentName(path);
   ```
   - Uses `helpers.cjs` → **✅ Use `helpers.rsc`**

2. **Custom Hook Detection** (line 40)
   ```javascript
   if (isCustomHook(path)) {
       return processCustomHook(path, state);
   }
   ```
   - Uses `analyzers/hookDetector.cjs` → **✅ Use `hook_detector.rsc`**

3. **Component Name Validation** (line 45)
   ```javascript
   if (componentName[0] !== componentName[0].toUpperCase()) return;
   ```
   - Should use `is_component_name()` from **helpers.rsc**

4. **Component Initialization** (lines 63-90)
   ```javascript
   const component = {
       name: componentName,
       props: [],
       useState: [],
       useClientState: [],
       useStateX: [],
       useEffect: [],
       useRef: [],
       // ... many more fields
   };
   ```

5. **Imported Hooks Analysis** (line 53)
   ```javascript
   const importedHooks = analyzeImportedHooks(state.file.path, state);
   ```
   - Uses `analyzers/hookImports.cjs` → **✅ Use `hook_imports.rsc`**

6. **External Imports Tracking** (lines 93-121)
   - Track lodash, dayjs, etc. for client-side computation
   - Needed for hybrid rendering classification

7. **Props Extraction** (lines 123-160)
   - Extract from function parameters
   - TypeScript type annotation → C# type
   - Uses `types/typeConversion.cjs` → **✅ Use `type_conversion.rsc`**

8. **Hook Extraction** (lines 168-226)
   - Extract `useState`, `useEffect`, `useRef`, custom hooks
   - Extract local variables
   - Extract helper functions
   - Extract render body (JSX return statement)

9. **Prop Type Inference** (line 230)
   ```javascript
   inferPropTypes(component, body);
   ```
   - Uses `analyzers/propTypeInference.cjs` → **✅ Use `prop_type_inference.rsc`**

10. **Hex Path Assignment** (lines 234-246)
    ```javascript
    const pathGen = new HexPathGenerator();
    assignPathsToJSX(component.renderBody, '', pathGen, t, null, null, structuralChanges, isHotReload);
    ```
    - Uses `utils/hexPath.cjs` → **✅ Use `hex_path.rsc`**
    - Uses `utils/pathAssignment.cjs` → **TODO: Convert**

11. **Template Extraction** (lines 254-269)
    ```javascript
    extractTemplates(component);
    extractAttributeTemplates(component);
    extractLoopTemplates(component);
    extractStructuralTemplates(component);
    extractConditionalElementTemplates(component);
    extractExpressionTemplates(component);
    ```
    - Uses various `extractors/` modules → **✅ Many CONVERTED**

12. **Plugin Usage Analysis** (line 272)
    ```javascript
    component.pluginUsages = analyzePluginUsage(component.renderBody);
    ```
    - Uses `analyzers/analyzePluginUsage.cjs` → **✅ Use `analyze_plugin_usage.rsc`**

13. **Timeline Analysis** (line 277)
    ```javascript
    const timelineTemplates = analyzeTimeline(component);
    ```
    - Uses `analyzers/timelineAnalyzer.cjs` → **✅ Use `timeline_analyzer.rsc`**

14. **JSX Replacement** (line 286)
    ```javascript
    path.node.body.body = [t.returnStatement(t.nullLiteral())];
    ```
    - Replace JSX with `null` after all extraction

15. **Component Storage** (line 289)
    ```javascript
    state.file.minimactComponents.push(component);
    ```

### RustScript Equivalent Structure

```rustscript
use "../rustscript-plugin-minimact/utils/helpers.rsc" {
    escape_csharp_string,
    is_component_name,
    get_component_name
};
use "../rustscript-plugin-minimact/utils/hex_path.rsc" { HexPathGenerator };
use "../rustscript-plugin-minimact/types/type_conversion.rsc" {
    infer_type,
    ts_type_to_csharp_type
};
use "../rustscript-plugin-minimact/analyzers/classification.rsc" { classify_node };
use "../rustscript-plugin-minimact/analyzers/detection.rsc" {
    has_spread_props,
    has_dynamic_children
};
use "../rustscript-plugin-minimact/analyzers/hook_detector.rsc" { is_custom_hook };
use "../rustscript-plugin-minimact/analyzers/hook_imports.rsc" { analyze_imported_hooks };
use "../rustscript-plugin-minimact/analyzers/prop_type_inference.rsc" { infer_prop_types };
use "../rustscript-plugin-minimact/analyzers/timeline_analyzer.rsc" { analyze_timeline };

fn process_component(path: &FunctionPath, state: &mut State) -> Option<ComponentInfo> {
    // 1. Get component name
    let component_name = get_component_name(path)?;

    // 2. Check if it's a custom hook
    if is_custom_hook(path) {
        return process_custom_hook(path, state);
    }

    // 3. Validate component name (PascalCase)
    if !is_component_name(&component_name) {
        return None;
    }

    // 4. Initialize component struct
    let mut component = ComponentInfo::new(component_name);

    // 5. Analyze imported hooks
    let imported_hooks = analyze_imported_hooks(state.file.path, state);
    component.imported_hook_metadata = imported_hooks;

    // 6. Track external imports (lodash, dayjs, etc.)
    track_external_imports(state.file.path, &mut component);

    // 7. Extract props from parameters
    extract_props_from_params(path.node.params, &mut component);

    // 8. Extract hooks, local variables, helper functions
    extract_component_body(path, &mut component);

    // 9. Infer prop types from usage
    infer_prop_types(&mut component, path.node.body);

    // 10. Assign hex paths to JSX
    let mut path_gen = HexPathGenerator::default();
    let structural_changes = assign_paths_to_jsx(
        &mut component.render_body,
        "",
        &mut path_gen,
        state.is_hot_reload
    );
    component.structural_changes = structural_changes;

    // 11. Extract templates
    extract_templates(&mut component);
    extract_attribute_templates(&mut component);
    extract_loop_templates(&mut component);
    extract_structural_templates(&mut component);
    extract_conditional_element_templates(&mut component);
    extract_expression_templates(&mut component);

    // 12. Analyze plugin usage
    component.plugin_usages = analyze_plugin_usage(&component.render_body);

    // 13. Analyze timeline
    component.timeline_templates = analyze_timeline(&component);

    // 14. Replace JSX with null (after extraction)
    replace_jsx_with_null(path);

    Some(component)
}
```

## Integration Points with Converted Modules

### ✅ Already Converted and Tested (11 modules)

| Original File | Converted File | Test File | Status |
|--------------|---------------|-----------|--------|
| `utils/helpers.cjs` | `helpers.rsc` | `test_helpers.rsc` | ✅ PASSING |
| `utils/hexPath.cjs` | `hex_path.rsc` | `test_hex_path.rsc` | ✅ PASSING |
| `utils/styleConverter.cjs` | `style_converter.rsc` | `test_style_converter_integration.rsc` | ✅ PASSING |
| `types/typeConversion.cjs` | `type_conversion.rsc` | `test_type_conversion_integration.rsc` | ✅ PASSING |
| `analyzers/classification.cjs` | `classification.rsc` | `test_classification.rsc` | ✅ PASSING |
| `analyzers/detection.cjs` | `detection.rsc` | `test_detection.rsc` | ✅ PASSING |
| `analyzers/hookDetector.cjs` | `hook_detector.rsc` | `test_hook_detector.rsc` | ✅ PASSING |
| `extractors/.../isSimpleExpression.cjs` | `is_simple_expression.rsc` | `test_is_simple_expression.rsc` | ✅ PASSING |
| `extractors/.../buildMemberPath.cjs` | `build_member_path.rsc` | `test_build_member_path.rsc` | ✅ PASSING |
| `generators/.../handleStringMethods.cjs` | `string_methods.rsc` | `test_string_methods.rsc` | ✅ PASSING |

### 📝 TODO: Convert These Critical Files

1. **`utils/pathAssignment.cjs`** - Assigns hex paths to JSX tree
   - Critical for hot reload
   - Used in processComponent.cjs line 246

2. **`extractors/hooks.cjs`** - Extracts useState, useEffect, etc.
   - Core hook extraction logic

3. **`extractors/localVariables.cjs`** - Extracts local variables
   - Needed for component state tracking

4. **`extractors/templates.cjs`** - Main template extraction
   - Core prediction system

5. **`generators/csharpFile.cjs`** - Generates C# files
   - Final output generation

## Mapping processComponent.cjs to minimact_full.rsc

### Current minimact_full.rsc Issues

1. **❌ Duplicates logic** instead of using converted helpers
   - Has its own `is_pascal_case()` instead of using `is_component_name()`
   - Has its own `infer_csharp_type()` instead of using `infer_type()`
   - Has its own `expr_to_csharp()` that doesn't escape strings

2. **❌ Missing critical steps** from processComponent.cjs:
   - No imported hooks analysis
   - No external imports tracking
   - No prop type inference
   - No hex path assignment
   - No template extraction (multiple phases)
   - No plugin usage analysis
   - No timeline analysis

3. **❌ Incomplete C# generation**
   - Only generates skeleton class
   - Doesn't generate VNode tree from JSX
   - Missing method generation
   - Missing field generation

### Recommended Refactoring

**Replace `minimact_full.rsc` with modular structure:**

```
minimact-transpiler/
├── main.rsc              # Plugin entry point (like index.cjs)
├── process_component.rsc # Component processor (like processComponent.cjs)
└── (use all existing helper modules from rustscript-plugin-minimact/)
```

## Next Steps

1. **✅ DONE:** Convert helper utilities (helpers, hex_path, type_conversion, etc.)
   - 11/11 tests passing

2. **IN PROGRESS:** Create comprehensive integration
   - Mirror processComponent.cjs flow
   - Use all converted helpers

3. **TODO:** Convert remaining critical files
   - pathAssignment.cjs
   - hooks.cjs (extractor)
   - templates.cjs
   - csharpFile.cjs (generator)

4. **TODO:** Create full plugin equivalent
   - RustScript plugin that mirrors index.cjs
   - Calls process_component
   - Generates all output files

## Conclusion

The babel-plugin-minimact has a well-structured, modular architecture. The RustScript conversion should:

✅ **Mirror this structure** - Don't reinvent the wheel
✅ **Reuse converted helpers** - All tested and working
✅ **Follow the same flow** - processComponent.cjs is the blueprint
✅ **Generate dual targets** - Babel + SWC from one codebase

The current `minimact_full.rsc` is a starting point but needs significant refactoring to match the proven architecture of `processComponent.cjs`.
