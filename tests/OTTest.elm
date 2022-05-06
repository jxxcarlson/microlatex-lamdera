module OTTest exposing (suite)

import CollaborativeEditing.OT as OT exposing (Document, Operation(..))
import Expect exposing (..)
import Test exposing (..)


foo =
    1


test_ : String -> c -> c -> Test
test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


suite : Test
suite =
    describe "OT test"
        [ test_ "insert, 'x' at beginning" (OT.apply [ Insert "x" ] { id = "A", cursor = 0, x = 0, y = 0, content = "a" }) { id = "A", cursor = 1, x = 1, y = 0, content = "xa" }
        , test_ "insert, 'x' at end" (OT.apply [ Insert "x" ] { id = "A", cursor = 1, x = 1, y = 0, content = "a" }) { id = "A", cursor = 2, x = 2, y = 0, content = "ax" }
        , test_ "delete 1 char in middle" (OT.apply [ Delete 1 ] { id = "A", cursor = 1, x = 0, y = 0, content = "axb" }) { id = "A", cursor = 1, x = 0, y = 0, content = "ab" }
        , test_ "skip 2 chars" (OT.apply [ MoveCursor 2 ] { id = "A", cursor = 0, x = 0, y = 0, content = "abcd" }) { id = "A", cursor = 2, x = 2, y = 0, content = "abcd" }
        , test_ "hello world -> Hello, World!" (OT.apply ops { id = "A", cursor = 0, x = 0, y = 0, content = "hello world" }) { id = "A", cursor = 13, x = 13, y = 0, content = "Hello, World!" }
        , test_ "Skip 2" (OT.findOps { id = "A", cursor = 0, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 0, y = 0, content = "abcd" }) [ MoveCursor 2 ]
        , test_ "Reconcile Skip 2" (OT.reconcile { id = "A", cursor = 0, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 0, x = 0, y = 0, content = "abcd" }) { id = "A", cursor = 0, x = 0, y = 0, content = "abcd" }
        , test_ "Skip -1" (OT.findOps { id = "A", cursor = 2, x = 2, y = 0, content = "abcd" } { id = "A", cursor = 1, x = 1, y = 0, content = "abcd" }) [ MoveCursor -1 ]
        , test_ "Reconcile Skip -1" (OT.reconcile { id = "A", cursor = 2, x = 2, y = 0, content = "abcd" } { id = "A", cursor = 1, x = 1, y = 0, content = "abcd" }) { id = "A", cursor = 1, x = 1, y = 0, content = "abcd" }
        , test_ "Reconcile Insert 'x'" (OT.reconcile { id = "A", cursor = 1, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 1, y = 0, content = "axbcd" }) { id = "A", cursor = 2, x = 1, y = 0, content = "axbcd" }
        , test_ "find" (OT.findOps { id = "A", cursor = 1, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 0, y = 0, content = "axbcd" }) [ Insert "x" ]
        , test_ "Insert 'x' !!" (OT.apply [ Insert "x" ] { id = "A", cursor = 1, x = 1, y = 0, content = "abcd" }) { id = "A", cursor = 2, x = 2, y = 0, content = "axbcd" }
        , test_ "Insert 'x'" (OT.findOps { id = "A", cursor = 1, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 0, y = 0, content = "axbcd" }) [ Insert "x" ]
        , test_ "!!! Reconcile Insert 'x'" (OT.reconcile { id = "A", cursor = 1, x = 1, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 2, y = 0, content = "axbcd" }) { id = "A", cursor = 2, x = 2, y = 0, content = "axbcd" }
        , test_ "Delete 1" (OT.findOps { id = "A", cursor = 2, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 0, y = 0, content = "abd" }) [ Delete 1 ]
        , test_ "Reconcile Delete 1" (OT.reconcile { id = "A", cursor = 2, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 0, y = 0, content = "abd" }) { id = "A", cursor = 2, x = 0, y = 0, content = "abd" }
        , test_ "Delete back 1" (OT.findOps { id = "A", cursor = 2, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 1, x = 0, y = 0, content = "abd" }) [ MoveCursor 0, Delete 1 ]
        , test_ "Reconcile Delete back 1" (OT.reconcile { id = "A", cursor = 2, x = 0, y = 0, content = "abcd" } { id = "A", cursor = 2, x = 0, y = 0, content = "abd" }) { id = "A", cursor = 2, x = 0, y = 0, content = "abd" }
        ]


ops =
    [ Delete 1
    , Insert "H"
    , MoveCursor 4
    , Insert ","
    , MoveCursor 1
    , Delete 1
    , Insert "W"
    , MoveCursor 4
    , Insert "!"
    ]
