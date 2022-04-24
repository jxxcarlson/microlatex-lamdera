module Evergreen.V487.Compiler.Lambda exposing (..)

import Evergreen.V487.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V487.Parser.Expr.Expr
    }
