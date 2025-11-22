/**
 * Test for analyzers/classification.rsc
 *
 * Tests node classification based on dependencies
 */

use "../../../../rustscript-plugin-minimact/analyzers/classification.rsc" {
    classify_node,
    is_static,
    is_hybrid,
    Dependency
};

plugin TestClassification {
    fn test_classify_static_node() {
        // Empty dependency set = static
        let deps: HashSet<Dependency> = HashSet::new();
        let classification = classify_node(&deps);
        // Expected: "static"

        let is_static_result = is_static(&deps);
        // Expected: true
    }

    fn test_classify_client_node() {
        // All client dependencies
        let mut deps: HashSet<Dependency> = HashSet::new();
        deps.insert(Dependency {
            name: "useState",
            dep_type: "client",
        });
        deps.insert(Dependency {
            name: "count",
            dep_type: "client",
        });

        let classification = classify_node(&deps);
        // Expected: "client"

        let is_static_result = is_static(&deps);
        // Expected: false
    }

    fn test_classify_server_node() {
        // All server dependencies
        let mut deps: HashSet<Dependency> = HashSet::new();
        deps.insert(Dependency {
            name: "userId",
            dep_type: "server",
        });
        deps.insert(Dependency {
            name: "dbData",
            dep_type: "server",
        });

        let classification = classify_node(&deps);
        // Expected: "server"
    }

    fn test_classify_hybrid_node() {
        // Mixed client and server dependencies
        let mut deps: HashSet<Dependency> = HashSet::new();
        deps.insert(Dependency {
            name: "count",
            dep_type: "client",
        });
        deps.insert(Dependency {
            name: "userId",
            dep_type: "server",
        });

        let classification = classify_node(&deps);
        // Expected: "hybrid"

        let is_hybrid_result = is_hybrid(&deps);
        // Expected: true
    }
}
