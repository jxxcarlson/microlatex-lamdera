module Evergreen.V16.Compiler.Lambda exposing (..)

import Evergreen.V16.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V16.Parser.Expr.Expr
    }
