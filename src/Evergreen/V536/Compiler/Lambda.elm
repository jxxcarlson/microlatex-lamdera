module Evergreen.V536.Compiler.Lambda exposing (..)

import Evergreen.V536.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V536.Parser.Expr.Expr
    }
