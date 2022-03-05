module Evergreen.V72.Compiler.Lambda exposing (..)

import Evergreen.V72.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V72.Parser.Expr.Expr
    }
