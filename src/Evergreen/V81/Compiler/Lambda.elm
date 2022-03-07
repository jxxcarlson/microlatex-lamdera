module Evergreen.V81.Compiler.Lambda exposing (..)

import Evergreen.V81.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V81.Parser.Expr.Expr
    }
