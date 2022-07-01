module Evergreen.V681.Compiler.Lambda exposing (..)

import Evergreen.V681.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V681.Parser.Expr.Expr
    }
