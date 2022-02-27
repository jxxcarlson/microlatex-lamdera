module Evergreen.V13.Compiler.Acc exposing (..)

import Dict
import Evergreen.V13.Compiler.Lambda
import Evergreen.V13.Compiler.Vector


type alias Accumulator =
    { headingIndex : Evergreen.V13.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , environment : Dict.Dict String Evergreen.V13.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    }
