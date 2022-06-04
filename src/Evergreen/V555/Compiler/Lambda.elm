module Evergreen.V555.Compiler.Lambda exposing (..)

import Evergreen.V555.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V555.Parser.Expr.Expr
    }
