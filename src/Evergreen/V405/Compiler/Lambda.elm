module Evergreen.V405.Compiler.Lambda exposing (..)

import Evergreen.V405.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V405.Parser.Expr.Expr
    }
