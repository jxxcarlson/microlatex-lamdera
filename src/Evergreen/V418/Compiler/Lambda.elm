module Evergreen.V418.Compiler.Lambda exposing (..)

import Evergreen.V418.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V418.Parser.Expr.Expr
    }
