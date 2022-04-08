module Evergreen.V288.Compiler.Lambda exposing (..)

import Evergreen.V288.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V288.Parser.Expr.Expr
    }
