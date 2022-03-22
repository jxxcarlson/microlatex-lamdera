module Evergreen.V149.Compiler.Lambda exposing (..)

import Evergreen.V149.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V149.Parser.Expr.Expr
    }
