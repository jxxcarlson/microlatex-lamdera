module Evergreen.V718.Compiler.Lambda exposing (..)

import Evergreen.V718.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V718.Parser.Expr.Expr
    }
