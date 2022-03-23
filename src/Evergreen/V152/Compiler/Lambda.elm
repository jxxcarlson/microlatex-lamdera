module Evergreen.V152.Compiler.Lambda exposing (..)

import Evergreen.V152.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V152.Parser.Expr.Expr
    }
