module Evergreen.V198.Compiler.Lambda exposing (..)

import Evergreen.V198.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V198.Parser.Expr.Expr
    }
