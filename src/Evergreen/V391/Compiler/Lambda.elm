module Evergreen.V391.Compiler.Lambda exposing (..)

import Evergreen.V391.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V391.Parser.Expr.Expr
    }
