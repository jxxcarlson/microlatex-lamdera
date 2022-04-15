module Evergreen.V369.Compiler.Lambda exposing (..)

import Evergreen.V369.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V369.Parser.Expr.Expr
    }
