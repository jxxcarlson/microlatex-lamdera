module Evergreen.V477.Compiler.Lambda exposing (..)

import Evergreen.V477.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V477.Parser.Expr.Expr
    }
