module Evergreen.V390.Compiler.Lambda exposing (..)

import Evergreen.V390.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V390.Parser.Expr.Expr
    }
