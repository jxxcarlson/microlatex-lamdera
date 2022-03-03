module Evergreen.V41.Compiler.Lambda exposing (..)

import Evergreen.V41.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V41.Parser.Expr.Expr
    }
