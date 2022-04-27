module OTTest exposing (suite)

import Expect exposing (..)
import OT exposing (Document, Operation(..))
import Test exposing (..)


foo =
    1


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "OT test"
        [ test_ "insert, 'x' at beginning" (OT.apply [ Insert "x" ] { cursor = 0, x = 0, y = 0, content = "a" }) { cursor = 1, x = 1, y = 0, content = "xa" }
        , test_ "insert, 'x' at end" (OT.apply [ Insert "x" ] { cursor = 1, x = 1, y = 0, content = "a" }) { cursor = 2, x = 2, y = 0, content = "ax" }
        , test_ "delete 1 char in middle" (OT.apply [ Delete 1 ] { cursor = 1, x = 0, y = 0, content = "axb" }) { cursor = 1, x = 0, y = 0, content = "ab" }
        , test_ "skip 2 chars" (OT.apply [ Skip 2 ] { cursor = 0, x = 0, y = 0, content = "abcd" }) { cursor = 2, x = 2, y = 0, content = "abcd" }
        , test_ "hello world -> Hello, World!" (OT.apply ops { cursor = 0, x = 0, y = 0, content = "hello world" }) { cursor = 13, x = 13, y = 0, content = "Hello, World!" }
        , test_ "Skip 2" (OT.findOps { cursor = 0, x = 0, y = 0, content = "abcd" } { cursor = 2, x = 0, y = 0, content = "abcd" }) [ Skip 2 ]
        , test_ "Reconcile Skip 2" (OT.reconcile { cursor = 0, x = 0, y = 0, content = "abcd" } { cursor = 0, x = 0, y = 0, content = "abcd" }) { cursor = 0, x = 0, y = 0, content = "abcd" }
        , test_ "Skip -1" (OT.findOps { cursor = 2, x = 2, y = 0, content = "abcd" } { cursor = 1, x = 1, y = 0, content = "abcd" }) [ Skip -1 ]
        , test_ "Reconcile Skip -1" (OT.reconcile { cursor = 2, x = 2, y = 0, content = "abcd" } { cursor = 1, x = 1, y = 0, content = "abcd" }) { cursor = 1, x = 1, y = 0, content = "abcd" }
        , test_ "Reconcile Insert 'x'" (OT.reconcile { cursor = 1, x = 0, y = 0, content = "abcd" } { cursor = 2, x = 1, y = 0, content = "axbcd" }) { cursor = 2, x = 1, y = 0, content = "axbcd" }
        , test_ "find" (OT.findOps { cursor = 1, x = 0, y = 0, content = "abcd" } { cursor = 2, x = 0, y = 0, content = "axbcd" }) [ Insert "x" ]
        , test_ "Insert 'x' !!" (OT.apply [ Insert "x" ] { cursor = 1, x = 1, y = 0, content = "abcd" }) { cursor = 2, x = 2, y = 0, content = "axbcd" }
        , test_ "Insert 'x'" (OT.findOps { cursor = 1, x = 0, y = 0, content = "abcd" } { cursor = 2, x = 0, y = 0, content = "axbcd" }) [ Insert "x" ]
        , test_ "!!! Reconcile Insert 'x'" (OT.reconcile { cursor = 1, x = 1, y = 0, content = "abcd" } { cursor = 2, x = 2, y = 0, content = "axbcd" }) { cursor = 2, x = 2, y = 0, content = "axbcd" }
        , test_ "Delete 1" (OT.findOps { cursor = 2, x = 0, y = 0, content = "abcd" } { cursor = 2, x = 0, y = 0, content = "abd" }) [ Delete 1 ]
        , test_ "Reconcile Delete 1" (OT.reconcile { cursor = 2, x = 0, y = 0, content = "abcd" } { cursor = 2, x = 0, y = 0, content = "abd" }) { cursor = 2, x = 0, y = 0, content = "abd" }
        , test_ "Delete back 1" (OT.findOps { cursor = 2, x = 0, y = 0, content = "abcd" } { cursor = 1, x = 0, y = 0, content = "abd" }) [ Skip 0, Delete 1 ]
        , test_ "Reconcile Delete back 1" (OT.reconcile { cursor = 2, x = 0, y = 0, content = "abcd" } { cursor = 2, x = 0, y = 0, content = "abd" }) { cursor = 2, x = 0, y = 0, content = "abd" }
        ]


ops =
    [ Delete 1
    , Insert "H"
    , Skip 4
    , Insert ","
    , Skip 1
    , Delete 1
    , Insert "W"
    , Skip 4
    , Insert "!"
    ]
