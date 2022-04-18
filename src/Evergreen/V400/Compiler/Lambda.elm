module Evergreen.V400.Compiler.Lambda exposing (..)

import Evergreen.V400.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V400.Parser.Expr.Expr
    }
