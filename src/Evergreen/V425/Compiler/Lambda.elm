module Evergreen.V425.Compiler.Lambda exposing (..)

import Evergreen.V425.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V425.Parser.Expr.Expr
    }
