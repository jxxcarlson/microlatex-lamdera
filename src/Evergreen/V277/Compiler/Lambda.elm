module Evergreen.V277.Compiler.Lambda exposing (..)

import Evergreen.V277.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V277.Parser.Expr.Expr
    }
