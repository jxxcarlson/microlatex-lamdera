module Evergreen.V295.Compiler.Lambda exposing (..)

import Evergreen.V295.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V295.Parser.Expr.Expr
    }
