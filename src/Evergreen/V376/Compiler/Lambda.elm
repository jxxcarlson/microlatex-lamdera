module Evergreen.V376.Compiler.Lambda exposing (..)

import Evergreen.V376.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V376.Parser.Expr.Expr
    }
