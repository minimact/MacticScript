/**
 * Test for analyzers/hook_detector.rsc
 *
 * Tests custom hook detection based on naming and parameter patterns
 */

plugin TestHookDetector {
    // Use visitor pattern to test hook detection on actual function declarations

    fn visit_function_declaration(func: &mut FunctionDeclaration, ctx: &Context) {
        // Test cases:
        //
        // Valid custom hooks:
        // function useCounter(namespace, start) { ... }
        // function useData(namespace: string) { ... }
        // function useForm(namespace, config) { ... }
        //
        // Invalid (not hooks):
        // function counter(namespace) { ... }  // Doesn't start with 'use'
        // function useSomething() { ... }      // No namespace parameter
        // function getData() { ... }           // Doesn't start with 'use'

        func.visit_children(self);
    }

    fn visit_variable_declaration(var_decl: &mut VariableDeclaration, ctx: &Context) {
        // Test cases for arrow functions:
        //
        // Valid:
        // const useCounter = (namespace, start) => { ... }
        // const useData = (namespace: string) => { ... }
        //
        // Invalid:
        // const counter = (namespace) => { ... }  // Doesn't start with 'use'
        // const useSomething = () => { ... }      // No namespace parameter

        var_decl.visit_children(self);
    }
}
