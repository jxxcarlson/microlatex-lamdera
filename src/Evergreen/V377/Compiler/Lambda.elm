module Evergreen.V377.Compiler.Lambda exposing (..)

import Evergreen.V377.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V377.Parser.Expr.Expr
    }
