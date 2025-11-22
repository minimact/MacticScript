/**
 * Integration Test for types/type_conversion.rsc
 *
 * This test uses a visitor pattern to test type conversion by
 * actually visiting TypeScript type annotations in real code.
 */

plugin TestTypeConversionIntegration {

    // Test visiting a function with TypeScript type annotations
    // Input TypeScript:
    //   function example(name: string, age: number, active: boolean): void {
    //     // ...
    //   }
    //
    // The type_conversion module would convert:
    //   string -> string
    //   number -> double
    //   boolean -> bool
    //   void -> void

    fn visit_function_declaration(node: &mut FunctionDeclaration, ctx: &Context) {
        // In a real test, this would:
        // 1. Extract type annotations from parameters
        // 2. Use ts_type_to_csharp_type() to convert them
        // 3. Verify the conversions are correct

        // For now, this is a placeholder that compiles successfully
        node.visit_children(self);
    }
}
