module Evergreen.V147.Compiler.Lambda exposing (..)

import Evergreen.V147.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V147.Parser.Expr.Expr
    }
