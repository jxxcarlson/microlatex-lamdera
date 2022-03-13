module Evergreen.V86.Compiler.Lambda exposing (..)

import Evergreen.V86.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V86.Parser.Expr.Expr
    }
