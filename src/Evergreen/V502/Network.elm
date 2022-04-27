module Evergreen.V502.Network exposing (..)

import Dict
import Evergreen.V502.OT


type alias EditEvent =
    { userId : String
    , dp : Int
    , dx : Int
    , dy : Int
    , operations : List Evergreen.V502.OT.Operation
    }


type alias UserId =
    String


type alias ServerState =
    { cursorPositions :
        Dict.Dict
            UserId
            { x : Int
            , y : Int
            , p : Int
            }
    , document : Evergreen.V502.OT.Document
    }


type alias NetworkModel =
    { localMsgs : List EditEvent
    , serverState : ServerState
    }
