module Evergreen.V273.Compiler.Lambda exposing (..)

import Evergreen.V273.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V273.Parser.Expr.Expr
    }
