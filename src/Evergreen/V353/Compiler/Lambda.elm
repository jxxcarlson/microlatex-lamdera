module Evergreen.V353.Compiler.Lambda exposing (..)

import Evergreen.V353.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V353.Parser.Expr.Expr
    }
