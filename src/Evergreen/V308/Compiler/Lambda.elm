module Evergreen.V308.Compiler.Lambda exposing (..)

import Evergreen.V308.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V308.Parser.Expr.Expr
    }
