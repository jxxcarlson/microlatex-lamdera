module Evergreen.V683.Compiler.Lambda exposing (..)

import Evergreen.V683.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V683.Parser.Expr.Expr
    }
