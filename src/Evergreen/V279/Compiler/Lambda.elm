module Evergreen.V279.Compiler.Lambda exposing (..)

import Evergreen.V279.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V279.Parser.Expr.Expr
    }
