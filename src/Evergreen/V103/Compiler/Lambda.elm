module Evergreen.V103.Compiler.Lambda exposing (..)

import Evergreen.V103.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V103.Parser.Expr.Expr
    }
