module Evergreen.V7.Compiler.Lambda exposing (..)

import Evergreen.V7.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V7.Parser.Expr.Expr
    }
