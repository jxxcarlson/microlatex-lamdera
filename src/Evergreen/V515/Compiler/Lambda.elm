module Evergreen.V515.Compiler.Lambda exposing (..)

import Evergreen.V515.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V515.Parser.Expr.Expr
    }
