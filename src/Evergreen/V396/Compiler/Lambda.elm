module Evergreen.V396.Compiler.Lambda exposing (..)

import Evergreen.V396.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V396.Parser.Expr.Expr
    }
