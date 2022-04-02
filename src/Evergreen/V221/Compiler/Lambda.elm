module Evergreen.V221.Compiler.Lambda exposing (..)

import Evergreen.V221.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V221.Parser.Expr.Expr
    }
