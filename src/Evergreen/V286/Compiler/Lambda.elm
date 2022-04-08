module Evergreen.V286.Compiler.Lambda exposing (..)

import Evergreen.V286.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V286.Parser.Expr.Expr
    }
