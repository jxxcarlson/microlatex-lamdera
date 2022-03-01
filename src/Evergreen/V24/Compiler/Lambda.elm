module Evergreen.V24.Compiler.Lambda exposing (..)

import Evergreen.V24.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V24.Parser.Expr.Expr
    }
