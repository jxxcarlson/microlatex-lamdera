module Evergreen.V24.Compiler.Acc exposing (..)

import Dict
import Evergreen.V24.Compiler.Lambda
import Evergreen.V24.Compiler.Vector


type alias Accumulator =
    { headingIndex : Evergreen.V24.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , environment : Dict.Dict String Evergreen.V24.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    }
