module Evergreen.V193.Compiler.Lambda exposing (..)

import Evergreen.V193.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V193.Parser.Expr.Expr
    }
