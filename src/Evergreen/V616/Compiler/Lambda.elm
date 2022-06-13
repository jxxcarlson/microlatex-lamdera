module Evergreen.V616.Compiler.Lambda exposing (..)

import Evergreen.V616.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V616.Parser.Expr.Expr
    }
