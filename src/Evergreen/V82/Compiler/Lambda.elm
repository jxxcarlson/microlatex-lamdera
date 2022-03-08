module Evergreen.V82.Compiler.Lambda exposing (..)

import Evergreen.V82.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V82.Parser.Expr.Expr
    }
