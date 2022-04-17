module Network exposing (..)

import Dict exposing (Dict)


type alias UserId =
    String


type Event
    = MovedCursor UserId { xOffset : Int, yOffset : Int } -- Offset relative to the previous cursor position
    | TypedText UserId String


type alias ServerState =
    { cursorPositions : Dict UserId { x : Int, y : Int }
    , document : String
    }
