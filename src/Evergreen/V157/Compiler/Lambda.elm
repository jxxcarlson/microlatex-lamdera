module Evergreen.V157.Compiler.Lambda exposing (..)

import Evergreen.V157.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V157.Parser.Expr.Expr
    }
