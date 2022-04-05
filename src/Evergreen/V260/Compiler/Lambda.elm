module Evergreen.V260.Compiler.Lambda exposing (..)

import Evergreen.V260.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V260.Parser.Expr.Expr
    }
