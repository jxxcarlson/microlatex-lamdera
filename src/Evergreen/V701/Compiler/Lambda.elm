module Evergreen.V701.Compiler.Lambda exposing (..)

import Evergreen.V701.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V701.Parser.Expr.Expr
    }
