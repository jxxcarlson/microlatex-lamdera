module Evergreen.V55.Compiler.Lambda exposing (..)

import Evergreen.V55.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V55.Parser.Expr.Expr
    }
