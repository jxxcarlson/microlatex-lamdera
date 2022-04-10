module Evergreen.V334.Compiler.Lambda exposing (..)

import Evergreen.V334.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V334.Parser.Expr.Expr
    }
