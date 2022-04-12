module Evergreen.V359.Compiler.Lambda exposing (..)

import Evergreen.V359.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V359.Parser.Expr.Expr
    }
