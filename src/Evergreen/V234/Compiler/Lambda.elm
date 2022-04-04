module Evergreen.V234.Compiler.Lambda exposing (..)

import Evergreen.V234.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V234.Parser.Expr.Expr
    }
