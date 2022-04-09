module Evergreen.V302.Compiler.Lambda exposing (..)

import Evergreen.V302.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V302.Parser.Expr.Expr
    }
