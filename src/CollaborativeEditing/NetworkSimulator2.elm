module CollaborativeEditing.NetworkSimulator2 exposing (..)

import Dict


initialModel =
    { localMsgs = []
    , serverState =
        { cursorPositions =
            Dict.fromList
                [ ( "A", { p = 0, x = 0, y = 0 } )
                , ( "B", { p = 0, x = 0, y = 0 } )
                ]
        , document =
            { content = "| title\nAAA\n\n0"
            , cursor = 0
            , id = "111"
            , x = 14
            , y = 0
            }
        }
    }


otDoc1 =
    initialModel.serverState.document
