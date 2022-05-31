module Evergreen.V537.Compiler.Lambda exposing (..)

import Evergreen.V537.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V537.Parser.Expr.Expr
    }
