/**
 * Test use statement syntax
 */

use "./test.rsc" { foo, bar };

plugin TestUseSyntax {
    fn test() {
        let x = 1;
    }
}
