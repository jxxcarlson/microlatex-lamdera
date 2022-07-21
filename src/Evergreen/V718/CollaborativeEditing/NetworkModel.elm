module Evergreen.V718.CollaborativeEditing.NetworkModel exposing (..)

import Dict
import Evergreen.V718.CollaborativeEditing.OT


type alias EditEvent =
    { docId : String
    , userId : String
    , dp : Int
    , operation : Evergreen.V718.CollaborativeEditing.OT.Operation
    }


type alias UserId =
    String


type alias ServerState =
    { cursorPositions : Dict.Dict UserId Int
    , document : Evergreen.V718.CollaborativeEditing.OT.Document
    }


type alias NetworkModel =
    { localMsgs : List EditEvent
    , serverState : ServerState
    }
