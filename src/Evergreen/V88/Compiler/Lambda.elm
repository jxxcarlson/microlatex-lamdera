module Evergreen.V88.Compiler.Lambda exposing (..)

import Evergreen.V88.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V88.Parser.Expr.Expr
    }
