/**
 * Test for types/type_conversion.rsc
 *
 * Tests:
 * - ts_type_to_csharp_type
 * - infer_type
 */

use "../../../rustscript-plugin-minimact/types/type_conversion.rsc" {
    ts_type_to_csharp_type,
    infer_type
};

plugin TestTypeConversion {
    fn test_ts_primitive_types() {
        // string -> string
        let ts_string = TSStringKeyword {};
        let result1 = ts_type_to_csharp_type(&ts_string);
        // result1 should be "string"

        // number -> double
        let ts_number = TSNumberKeyword {};
        let result2 = ts_type_to_csharp_type(&ts_number);
        // result2 should be "double"

        // boolean -> bool
        let ts_boolean = TSBooleanKeyword {};
        let result3 = ts_type_to_csharp_type(&ts_boolean);
        // result3 should be "bool"

        // any -> dynamic
        let ts_any = TSAnyKeyword {};
        let result4 = ts_type_to_csharp_type(&ts_any);
        // result4 should be "dynamic"

        // void -> void
        let ts_void = TSVoidKeyword {};
        let result5 = ts_type_to_csharp_type(&ts_void);
        // result5 should be "void"
    }

    fn test_ts_array_types() {
        // string[] -> List<string>
        let ts_string_array = TSArrayType {
            element_type: TSStringKeyword {},
        };
        let result1 = ts_type_to_csharp_type(&ts_string_array);
        // result1 should be "List<string>"

        // number[] -> List<double>
        let ts_number_array = TSArrayType {
            element_type: TSNumberKeyword {},
        };
        let result2 = ts_type_to_csharp_type(&ts_number_array);
        // result2 should be "List<double>"
    }

    fn test_ts_type_reference() {
        // Custom type reference: MyType -> MyType
        let ts_type_ref = TSTypeReference {
            type_name: Identifier { name: "MyType" },
        };
        let result1 = ts_type_to_csharp_type(&ts_type_ref);
        // result1 should be "MyType"

        // Test @minimact/mvc types
        let ts_decimal = TSTypeReference {
            type_name: Identifier { name: "decimal" },
        };
        let result2 = ts_type_to_csharp_type(&ts_decimal);
        // result2 should be "decimal"

        let ts_int = TSTypeReference {
            type_name: Identifier { name: "int" },
        };
        let result3 = ts_type_to_csharp_type(&ts_int);
        // result3 should be "int"

        let ts_guid = TSTypeReference {
            type_name: Identifier { name: "Guid" },
        };
        let result4 = ts_type_to_csharp_type(&ts_guid);
        // result4 should be "Guid"

        let ts_datetime = TSTypeReference {
            type_name: Identifier { name: "DateTime" },
        };
        let result5 = ts_type_to_csharp_type(&ts_datetime);
        // result5 should be "DateTime"
    }

    fn test_minimact_numeric_types() {
        // int32 -> int
        let ts_int32 = TSTypeReference {
            type_name: Identifier { name: "int32" },
        };
        let result1 = ts_type_to_csharp_type(&ts_int32);
        // result1 should be "int"

        // int64 -> long
        let ts_int64 = TSTypeReference {
            type_name: Identifier { name: "int64" },
        };
        let result2 = ts_type_to_csharp_type(&ts_int64);
        // result2 should be "long"

        // float -> float
        let ts_float = TSTypeReference {
            type_name: Identifier { name: "float" },
        };
        let result3 = ts_type_to_csharp_type(&ts_float);
        // result3 should be "float"

        // float64 -> double
        let ts_float64 = TSTypeReference {
            type_name: Identifier { name: "float64" },
        };
        let result4 = ts_type_to_csharp_type(&ts_float64);
        // result4 should be "double"

        // short -> short
        let ts_short = TSTypeReference {
            type_name: Identifier { name: "short" },
        };
        let result5 = ts_type_to_csharp_type(&ts_short);
        // result5 should be "short"

        // byte -> byte
        let ts_byte = TSTypeReference {
            type_name: Identifier { name: "byte" },
        };
        let result6 = ts_type_to_csharp_type(&ts_byte);
        // result6 should be "byte"
    }

    fn test_minimact_date_types() {
        // DateOnly -> DateOnly
        let ts_date_only = TSTypeReference {
            type_name: Identifier { name: "DateOnly" },
        };
        let result1 = ts_type_to_csharp_type(&ts_date_only);
        // result1 should be "DateOnly"

        // TimeOnly -> TimeOnly
        let ts_time_only = TSTypeReference {
            type_name: Identifier { name: "TimeOnly" },
        };
        let result2 = ts_type_to_csharp_type(&ts_time_only);
        // result2 should be "TimeOnly"
    }

    fn test_infer_from_string_literal() {
        let expr = StringLiteral { value: "hello" };
        let result = infer_type(&expr);
        // result should be "string"
    }

    fn test_infer_from_numeric_literal() {
        // Integer
        let expr1 = NumericLiteral { value: 42.0 };
        let result1 = infer_type(&expr1);
        // result1 should be "int"

        // Float
        let expr2 = NumericLiteral { value: 3.14 };
        let result2 = infer_type(&expr2);
        // result2 should be "double"

        // Zero
        let expr3 = NumericLiteral { value: 0.0 };
        let result3 = infer_type(&expr3);
        // result3 should be "int"
    }

    fn test_infer_from_boolean_literal() {
        let expr1 = BooleanLiteral { value: true };
        let result1 = infer_type(&expr1);
        // result1 should be "bool"

        let expr2 = BooleanLiteral { value: false };
        let result2 = infer_type(&expr2);
        // result2 should be "bool"
    }

    fn test_infer_from_null_literal() {
        let expr = NullLiteral {};
        let result = infer_type(&expr);
        // result should be "object"
    }

    fn test_infer_from_array_expression() {
        let expr = ArrayExpression {
            elements: vec![
                NumericLiteral { value: 1.0 },
                NumericLiteral { value: 2.0 },
                NumericLiteral { value: 3.0 },
            ],
        };
        let result = infer_type(&expr);
        // result should be "List<int>" (inferred from first element)
    }

    fn test_infer_from_object_expression() {
        let expr = ObjectExpression {
            properties: vec![
                ObjectProperty {
                    key: Identifier { name: "name" },
                    value: StringLiteral { value: "John" },
                },
                ObjectProperty {
                    key: Identifier { name: "age" },
                    value: NumericLiteral { value: 30.0 },
                },
            ],
        };
        let result = infer_type(&expr);
        // result should be "dynamic" (object literal)
    }

    fn test_infer_from_unknown_expression() {
        // Unknown expression types should default to "dynamic"
        let expr = Identifier { name: "someVariable" };
        let result = infer_type(&expr);
        // result should be "dynamic"
    }
}
