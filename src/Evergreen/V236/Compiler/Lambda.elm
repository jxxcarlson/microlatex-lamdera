module Evergreen.V236.Compiler.Lambda exposing (..)

import Evergreen.V236.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V236.Parser.Expr.Expr
    }
