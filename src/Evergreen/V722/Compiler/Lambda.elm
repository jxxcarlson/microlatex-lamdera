module Evergreen.V722.Compiler.Lambda exposing (..)

import Evergreen.V722.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V722.Parser.Expr.Expr
    }
