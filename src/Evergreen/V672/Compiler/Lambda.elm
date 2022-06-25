module Evergreen.V672.Compiler.Lambda exposing (..)

import Evergreen.V672.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V672.Parser.Expr.Expr
    }
