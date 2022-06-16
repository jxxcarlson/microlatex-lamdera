module Evergreen.V650.Compiler.Lambda exposing (..)

import Evergreen.V650.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V650.Parser.Expr.Expr
    }
