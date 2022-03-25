module Evergreen.V167.Compiler.Lambda exposing (..)

import Evergreen.V167.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V167.Parser.Expr.Expr
    }
