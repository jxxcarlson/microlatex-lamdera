module Evergreen.V352.Compiler.Lambda exposing (..)

import Evergreen.V352.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V352.Parser.Expr.Expr
    }
