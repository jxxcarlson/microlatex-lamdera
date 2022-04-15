module Evergreen.V375.Compiler.Lambda exposing (..)

import Evergreen.V375.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V375.Parser.Expr.Expr
    }
