module Evergreen.V712.Compiler.Lambda exposing (..)

import Evergreen.V712.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V712.Parser.Expr.Expr
    }
