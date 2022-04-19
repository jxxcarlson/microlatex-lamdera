module Evergreen.V416.Compiler.Lambda exposing (..)

import Evergreen.V416.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V416.Parser.Expr.Expr
    }
