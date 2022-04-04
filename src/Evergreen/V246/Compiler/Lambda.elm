module Evergreen.V246.Compiler.Lambda exposing (..)

import Evergreen.V246.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V246.Parser.Expr.Expr
    }
