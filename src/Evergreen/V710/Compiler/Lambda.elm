module Evergreen.V710.Compiler.Lambda exposing (..)

import Evergreen.V710.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V710.Parser.Expr.Expr
    }
