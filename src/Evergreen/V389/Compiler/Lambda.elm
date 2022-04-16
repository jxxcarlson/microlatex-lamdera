module Evergreen.V389.Compiler.Lambda exposing (..)

import Evergreen.V389.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V389.Parser.Expr.Expr
    }
