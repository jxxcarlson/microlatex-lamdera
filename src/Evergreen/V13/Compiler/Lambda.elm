module Evergreen.V13.Compiler.Lambda exposing (..)

import Evergreen.V13.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V13.Parser.Expr.Expr
    }
