module Evergreen.V12.Compiler.Lambda exposing (..)

import Evergreen.V12.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V12.Parser.Expr.Expr
    }
