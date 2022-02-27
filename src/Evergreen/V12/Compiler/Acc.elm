module Evergreen.V12.Compiler.Acc exposing (..)

import Dict
import Evergreen.V12.Compiler.Lambda
import Evergreen.V12.Compiler.Vector


type alias Accumulator =
    { headingIndex : Evergreen.V12.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , environment : Dict.Dict String Evergreen.V12.Compiler.Lambda.Lambda
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    }
