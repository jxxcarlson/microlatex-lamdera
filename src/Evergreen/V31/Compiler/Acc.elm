module Evergreen.V31.Compiler.Acc exposing (..)

import Dict
import Evergreen.V31.Compiler.Lambda
import Evergreen.V31.Compiler.Vector


type alias Accumulator =
    { headingIndex : Evergreen.V31.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , environment : Dict.Dict String Evergreen.V31.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    }
