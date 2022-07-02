module Evergreen.V684.Compiler.Lambda exposing (..)

import Evergreen.V684.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V684.Parser.Expr.Expr
    }
