module ReconcileChanges exposing (suite)

import Diff.Change
import Expect exposing (..)
import Test exposing (..)


reconcile : String -> String -> String
reconcile original modified =
    Diff.Change.reconcile (Diff.Change.changes original modified) original


test_ label original modified =
    test label <| \_ -> equal modified (reconcile original modified)


suite : Test
suite =
    Test.only <|
        describe "reconciliation of diffs"
            [ test_ "append 'x'" "a" "ax"
            , test_ "prepend 'x'" "a" "xa"
            , test_ "insert 'x' in middle" "ab" "axb"
            , test_ "delete 'x at end" "ax" "a"
            , test_ "delete 'x at beginning" "xa" "a"
            , test_ "delete 'x at middle" "axb" "ab"
            ]
