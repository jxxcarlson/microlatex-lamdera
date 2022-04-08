module Evergreen.V289.Compiler.Lambda exposing (..)

import Evergreen.V289.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V289.Parser.Expr.Expr
    }
