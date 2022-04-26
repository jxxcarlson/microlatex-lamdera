module Evergreen.V500.Compiler.Lambda exposing (..)

import Evergreen.V500.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V500.Parser.Expr.Expr
    }
