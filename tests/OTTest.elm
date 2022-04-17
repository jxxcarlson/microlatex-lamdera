module OTTest exposing (suite)

import Expect exposing (..)
import OT exposing (Document, Operation(..))
import Test exposing (..)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "OT test"
        [ test_ "insert, 'x' at beginning" (OT.apply [ Insert "x" ] { cursor = 0, content = "a" }) { cursor = 1, content = "xa" }
        , test_ "insert, 'x' at end" (OT.apply [ Insert "x" ] { cursor = 1, content = "a" }) { cursor = 2, content = "ax" }
        , test_ "delete 1 char in middle" (OT.apply [ Delete 1 ] { cursor = 1, content = "axb" }) { cursor = 1, content = "ab" }
        , test_ "skip 2 chars" (OT.apply [ Skip 2 ] { cursor = 0, content = "abcd" }) { cursor = 2, content = "abcd" }
        , test_ "hello world -> Hello, World!" (OT.apply ops { cursor = 0, content = "hello world" }) { cursor = 13, content = "Hello, World!" }
        , test_ "Skip 2" (OT.findOps { cursor = 0, content = "abcd" } { cursor = 2, content = "abcd" }) [ Skip 2 ]
        , test_ "Reconcile Skip 2" (OT.reconcile { cursor = 0, content = "abcd" } { cursor = 0, content = "abcd" }) { cursor = 0, content = "abcd" }
        , test_ "Skip -1" (OT.findOps { cursor = 2, content = "abcd" } { cursor = 1, content = "abcd" }) [ Skip -1 ]
        , test_ "Reconcile Skip -1" (OT.reconcile { cursor = 2, content = "abcd" } { cursor = 1, content = "abcd" }) { cursor = 1, content = "abcd" }
        , test_ "Reconcile Insert 'x'" (OT.reconcile { cursor = 1, content = "abcd" } { cursor = 2, content = "axbcd" }) { cursor = 2, content = "axbcd" }
        , test_ "find" (OT.findOps { cursor = 1, content = "abcd" } { cursor = 2, content = "axbcd" }) [ Insert "x" ]
        , test_ "Insert 'x' !!" (OT.apply [ Insert "x" ] { cursor = 1, content = "abcd" }) { cursor = 2, content = "axbcd" }
        , test_ "Insert 'x'" (OT.findOps { cursor = 1, content = "abcd" } { cursor = 2, content = "abxcd" }) [ Insert "x" ]
        , test_ "Reconcile Insert 'x'" (OT.reconcile { cursor = 1, content = "abcd" } { cursor = 2, content = "abxcd" }) { cursor = 2, content = "abxcd" }
        , test_ "Delete 1" (OT.findOps { cursor = 2, content = "abcd" } { cursor = 2, content = "abd" }) [ Delete 1 ]
        , test_ "Reconcile Delete 1" (OT.reconcile { cursor = 2, content = "abcd" } { cursor = 2, content = "abd" }) { cursor = 2, content = "abd" }
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
