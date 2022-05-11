module Evergreen.V503.Compiler.Lambda exposing (..)

import Evergreen.V503.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V503.Parser.Expr.Expr
    }
