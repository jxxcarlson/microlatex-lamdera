module Evergreen.V154.Compiler.Lambda exposing (..)

import Evergreen.V154.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V154.Parser.Expr.Expr
    }
