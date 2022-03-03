module Evergreen.V41.Compiler.Acc exposing (..)

import Dict
import Evergreen.V41.Compiler.Lambda
import Evergreen.V41.Compiler.Vector


type alias Accumulator =
    { headingIndex : Evergreen.V41.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , numberedBlockNames : List String
    , environment : Dict.Dict String Evergreen.V41.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    }
