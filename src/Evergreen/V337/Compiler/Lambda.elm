module Evergreen.V337.Compiler.Lambda exposing (..)

import Evergreen.V337.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V337.Parser.Expr.Expr
    }
