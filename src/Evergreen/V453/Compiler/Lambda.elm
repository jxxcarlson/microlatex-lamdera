module Evergreen.V453.Compiler.Lambda exposing (..)

import Evergreen.V453.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V453.Parser.Expr.Expr
    }
