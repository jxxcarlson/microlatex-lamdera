module Evergreen.V281.Compiler.Lambda exposing (..)

import Evergreen.V281.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V281.Parser.Expr.Expr
    }
