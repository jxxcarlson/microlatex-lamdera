module Evergreen.V447.Compiler.Lambda exposing (..)

import Evergreen.V447.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V447.Parser.Expr.Expr
    }
