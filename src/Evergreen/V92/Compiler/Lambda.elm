module Evergreen.V92.Compiler.Lambda exposing (..)

import Evergreen.V92.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V92.Parser.Expr.Expr
    }
