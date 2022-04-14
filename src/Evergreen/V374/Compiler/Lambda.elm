module Evergreen.V374.Compiler.Lambda exposing (..)

import Evergreen.V374.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V374.Parser.Expr.Expr
    }
