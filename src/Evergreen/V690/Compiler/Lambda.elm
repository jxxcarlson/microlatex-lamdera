module Evergreen.V690.Compiler.Lambda exposing (..)

import Evergreen.V690.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V690.Parser.Expr.Expr
    }
