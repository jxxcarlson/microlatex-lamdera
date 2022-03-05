module Evergreen.V72.Compiler.Acc exposing (..)

import Dict
import Evergreen.V72.Compiler.Lambda
import Evergreen.V72.Compiler.Vector
import Evergreen.V72.Parser.MathMacro


type alias TermLoc =
    { begin : Int
    , end : Int
    , id : String
    }


type alias Accumulator =
    { headingIndex : Evergreen.V72.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , numberedBlockNames : List String
    , environment : Dict.Dict String Evergreen.V72.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    , terms : Dict.Dict String TermLoc
    , mathMacroDict : Evergreen.V72.Parser.MathMacro.MathMacroDict
    }
