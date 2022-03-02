module Evergreen.V31.Compiler.Lambda exposing (..)

import Evergreen.V31.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V31.Parser.Expr.Expr
    }
