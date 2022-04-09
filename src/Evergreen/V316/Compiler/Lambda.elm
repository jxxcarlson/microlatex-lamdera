module Evergreen.V316.Compiler.Lambda exposing (..)

import Evergreen.V316.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V316.Parser.Expr.Expr
    }
