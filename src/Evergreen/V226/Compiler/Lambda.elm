module Evergreen.V226.Compiler.Lambda exposing (..)

import Evergreen.V226.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V226.Parser.Expr.Expr
    }
