module Evergreen.V348.Compiler.Lambda exposing (..)

import Evergreen.V348.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V348.Parser.Expr.Expr
    }
