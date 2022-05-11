module Evergreen.V509.NetworkModel exposing (..)

import Dict
import Evergreen.V509.OT


type alias EditEvent =
    { docId : String
    , userId : String
    , dp : Int
    , dx : Int
    , dy : Int
    , operations : List Evergreen.V509.OT.Operation
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
    , document : Evergreen.V509.OT.Document
    }


type alias NetworkModel =
    { localMsgs : List EditEvent
    , serverState : ServerState
    }
