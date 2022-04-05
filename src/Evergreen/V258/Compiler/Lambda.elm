module Evergreen.V258.Compiler.Lambda exposing (..)

import Evergreen.V258.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V258.Parser.Expr.Expr
    }
