module Evergreen.V16.Compiler.Acc exposing (..)

import Dict
import Evergreen.V16.Compiler.Lambda
import Evergreen.V16.Compiler.Vector


type alias Accumulator =
    { headingIndex : Evergreen.V16.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , environment : Dict.Dict String Evergreen.V16.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    }
