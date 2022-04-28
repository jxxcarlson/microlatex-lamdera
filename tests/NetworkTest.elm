module NetworkTest exposing (..)

import Expect exposing (..)
import Network exposing (NetworkModel)
import OT exposing (Document, Operation(..))
import Test exposing (..)


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput


modelS1 =
    Network.initWithUserAndContent "S" ""


modelA1 =
    Network.initWithUserAndContent "A" ""


modelB1 =
    Network.initWithUserAndContent "B" ""



-- EVENT A1


eventA1 =
    { userId = "A", dp = 0, dx = 0, dy = 0, operations = [ Insert "a" ] }


modelA2 =
    Network.updateFromUser eventA1 modelA1


docA2 =
    Network.getLocalDocument modelA2 |> Debug.log "docA2"


modelS2 =
    Network.updateFromUser eventA1 modelS1 |> Debug.log "modelS2"



-- EVENT B1


eventB1 =
    { userId = "B", dp = 0, dx = 0, dy = 0, operations = [ Insert "x" ] }


modelB2 =
    Network.updateFromUser eventB1 modelB1 |> Debug.log "modelB2"


docB2 =
    Network.getLocalDocument modelB2 |> Debug.log "docB2"


modelB3 =
    Network.updateFromBackend Network.applyEvent eventA1 modelB2 |> Debug.log "modelB3"


docB3 =
    Network.getLocalDocument modelB3 |> Debug.log "docB3"


suite : Test
suite =
    describe "OT scenario"
        [ test_ "User A inserts 'a' at beginning" docA2 { cursor = 1, x = 1, y = 0, content = "a" }
        , test_ "User B inserts 'x' at beginning" docB2 { cursor = 1, x = 1, y = 0, content = "x" }
        , test_ "User B gets update from backend with user A's edit" docB3 { cursor = 2, x = 2, y = 0, content = "ax" }
        ]
