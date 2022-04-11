module Evergreen.V351.Compiler.Lambda exposing (..)

import Evergreen.V351.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V351.Parser.Expr.Expr
    }
