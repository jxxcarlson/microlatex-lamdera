module Evergreen.V526.Compiler.Lambda exposing (..)

import Evergreen.V526.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V526.Parser.Expr.Expr
    }
