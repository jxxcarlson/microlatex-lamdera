module Evergreen.V533.Compiler.Lambda exposing (..)

import Evergreen.V533.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V533.Parser.Expr.Expr
    }
