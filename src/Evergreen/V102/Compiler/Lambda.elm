module Evergreen.V102.Compiler.Lambda exposing (..)

import Evergreen.V102.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V102.Parser.Expr.Expr
    }
