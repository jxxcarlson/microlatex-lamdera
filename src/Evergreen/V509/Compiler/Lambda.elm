module Evergreen.V509.Compiler.Lambda exposing (..)

import Evergreen.V509.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V509.Parser.Expr.Expr
    }
