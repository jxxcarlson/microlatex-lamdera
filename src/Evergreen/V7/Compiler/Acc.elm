module Evergreen.V7.Compiler.Acc exposing (..)

import Dict
import Evergreen.V7.Compiler.Lambda
import Evergreen.V7.Compiler.Vector


type alias Accumulator =
    { headingIndex : Evergreen.V7.Compiler.Vector.Vector
    , numberedItemIndex : Int
    , equationIndex : Int
    , definitionIndex : Int
    , remarkIndex : Int
    , exampleIndex : Int
    , lemmaIndex : Int
    , problemIndex : Int
    , theoremIndex : Int
    , environment : Dict.Dict String Evergreen.V7.Compiler.Lambda.Lambda
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    }
