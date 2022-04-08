module Evergreen.V296.Compiler.Lambda exposing (..)

import Evergreen.V296.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V296.Parser.Expr.Expr
    }
