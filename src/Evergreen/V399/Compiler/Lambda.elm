module Evergreen.V399.Compiler.Lambda exposing (..)

import Evergreen.V399.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V399.Parser.Expr.Expr
    }
