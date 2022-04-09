module Evergreen.V310.Compiler.Lambda exposing (..)

import Evergreen.V310.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V310.Parser.Expr.Expr
    }
