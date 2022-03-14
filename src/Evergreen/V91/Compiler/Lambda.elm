module Evergreen.V91.Compiler.Lambda exposing (..)

import Evergreen.V91.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V91.Parser.Expr.Expr
    }
