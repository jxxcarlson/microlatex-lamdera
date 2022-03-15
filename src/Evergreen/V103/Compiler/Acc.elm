module Evergreen.V103.Compiler.Acc exposing (..)

import Dict
import Evergreen.V103.Compiler.Lambda
import Evergreen.V103.Compiler.Vector
import Evergreen.V103.Parser.MathMacro


type alias TermLoc =
    { begin : Int
    , end : Int
    , id : String
    }


type alias Accumulator =
    { headingIndex : Evergreen.V103.Compiler.Vector.Vector
    , documentIndex : Evergreen.V103.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , itemVector : Evergreen.V103.Compiler.Vector.Vector
    , numberedItemDict :
        Dict.Dict
            String
            { level : Int
            , index : Int
            }
    , numberedBlockNames : List String
    , environment : Dict.Dict String Evergreen.V103.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    , terms : Dict.Dict String TermLoc
    , mathMacroDict : Evergreen.V103.Parser.MathMacro.MathMacroDict
    }
