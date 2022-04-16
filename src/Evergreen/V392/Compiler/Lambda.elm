module Evergreen.V392.Compiler.Lambda exposing (..)

import Evergreen.V392.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V392.Parser.Expr.Expr
    }
