module Evergreen.V674.Compiler.Lambda exposing (..)

import Evergreen.V674.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V674.Parser.Expr.Expr
    }
