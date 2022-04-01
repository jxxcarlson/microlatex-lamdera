module Evergreen.V194.Compiler.Lambda exposing (..)

import Evergreen.V194.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V194.Parser.Expr.Expr
    }
