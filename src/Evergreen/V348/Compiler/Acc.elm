module Evergreen.V348.Compiler.Acc exposing (..)

import Dict
import Evergreen.V348.Compiler.Lambda
import Evergreen.V348.Compiler.Vector
import Evergreen.V348.Parser.MathMacro


type alias TermLoc =
    { begin : Int
    , end : Int
    , id : String
    }


type alias Accumulator =
    { headingIndex : Evergreen.V348.Compiler.Vector.Vector
    , documentIndex : Evergreen.V348.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , itemVector : Evergreen.V348.Compiler.Vector.Vector
    , numberedItemDict :
        Dict.Dict
            String
            { level : Int
            , index : Int
            }
    , numberedBlockNames : List String
    , environment : Dict.Dict String Evergreen.V348.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    , terms : Dict.Dict String TermLoc
    , mathMacroDict : Evergreen.V348.Parser.MathMacro.MathMacroDict
    }
