module Evergreen.V59.Compiler.Acc exposing (..)

import Dict
import Evergreen.V59.Compiler.Lambda
import Evergreen.V59.Compiler.Vector


type alias TermLoc =
    { begin : Int
    , end : Int
    , id : String
    }


type alias Accumulator =
    { headingIndex : Evergreen.V59.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , numberedBlockNames : List String
    , environment : Dict.Dict String Evergreen.V59.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    , terms : Dict.Dict String TermLoc
    }
